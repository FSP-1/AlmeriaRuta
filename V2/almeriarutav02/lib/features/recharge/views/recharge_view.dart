import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recharge_viewmodel.dart';
import '../models/recharge_profile_model.dart';
import '../models/transport_card_model.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/recharge_widgets.dart';

class RechargeView extends StatefulWidget {
  final String? token;
  final bool isGuest;

  const RechargeView({
    super.key,
    required this.token,
    required this.isGuest,
  });

  @override
  State<RechargeView> createState() => _RechargeViewState();
}

class _RechargeViewState extends State<RechargeView> {
  bool _didShowInitialChooser = false;
  bool _hasChosenInitialCard = false;

  void _showInitialChooser(BuildContext context, RechargeViewModel vm) {
    if (_didShowInitialChooser) return;
    _didShowInitialChooser = true;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.72;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué tarjeta quieres usar?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes cambiarla después desde el menú superior derecho.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: vm.cardOptions.map((RechargeCardOption option) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            option.key == 'saldo_virtual'
                                ? Icons.account_balance_wallet
                                : Icons.credit_card,
                          ),
                          title: Text(option.title),
                          subtitle: Text(option.description),
                          onTap: () {
                            vm.setSelectedCardOption(option);
                            setState(() {
                              _hasChosenInitialCard = true;
                            });
                            Navigator.pop(sheetContext);

                            if (option.key == 'saldo_virtual') {
                              final saldoCard = vm.myCards.firstWhere(
                                (card) => card.name == 'Tarjeta Saldo Virtual',
                              );
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _showRechargeDialog(context, vm, saldoCard);
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RechargeViewModel(token: widget.token, isGuest: widget.isGuest),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recarga de tarjetas'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          actions: [
            Consumer<RechargeViewModel>(
              builder: (_, vm, _) {
                return CardOptionsMenuButton(
                  options: vm.cardOptions,
                  selectedKey: vm.selectedCardOption.key,
                  onSelected: vm.toggleCardOption,
                );
              },
            ),
          ],
        ),
        body: Consumer<RechargeViewModel>(
          builder: (_, vm, _) {
            if (!vm.profileResolved) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!vm.loadingProfile) {
              if (!_hasChosenInitialCard && vm.hasConfiguredCard) {
                _hasChosenInitialCard = true;
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (!vm.hasConfiguredCard) {
                  _showInitialChooser(context, vm);
                }
              });
            }

            if (!_hasChosenInitialCard) {
              return const SizedBox.shrink();
            }

            final selectedCard = vm.myCards.firstWhere(
              (card) => card.name == 'Tarjeta Saldo Virtual',
            );
            final selectedOption = vm.selectedCardOption;
            final selectedTransportCard = selectedOption.key == 'saldo_virtual'
                ? null
                : vm.cardByOption(selectedOption);

            return Column(
              children: [
                if (vm.loadingProfile)
                  const RechargeLoadingIndicator(),
                if (vm.profileError != null)
                  RechargeErrorBanner(error: vm.profileError!),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (selectedTransportCard != null && vm.isExpiringSoon(selectedTransportCard)) ...[
                        ExpirationWarningCard(
                          card: selectedTransportCard,
                          formattedExpiration: _format(selectedTransportCard.expirationDate!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (vm.hasSaldoCard)
                        SaldoCard(
                          card: selectedCard,
                          isExpired: vm.isExpired(selectedCard),
                          onAddSaldo: () => _showRechargeDialog(context, vm, selectedCard),
                        )
                      else
                        SaldoSetupCard(
                          onCreate: () {
                            final option = vm.cardOptions.firstWhere((o) => o.key == 'saldo_virtual');
                            vm.setSelectedCardOption(option);
                            final saldoCard = vm.myCards.firstWhere((c) => c.name == 'Tarjeta Saldo Virtual');
                            _showRechargeDialog(context, vm, saldoCard);
                          },
                        ),
                      if (selectedTransportCard != null) ...[
                        const SizedBox(height: 12),
                        TransportCard(
                          card: selectedTransportCard,
                          isExpired: vm.isExpired(selectedTransportCard),
                          canRecharge: vm.canRecharge(selectedTransportCard),
                          amount: vm.getRechargeAmount(selectedTransportCard),
                          expirationText: selectedTransportCard.expirationDate != null
                              ? 'Caduca: ${_format(selectedTransportCard.expirationDate!)}'
                              : 'Sin caducidad marcada',
                          onRenew: () => _showRechargeDialog(context, vm, selectedTransportCard),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        const AdditionalCardHint(),
                      ],
                      if (selectedCard.history.isEmpty)
                        const FirstRechargeHint(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRechargeDialog(BuildContext context, RechargeViewModel vm, card) {
    final availablePaymentMethods = vm.paymentMethodsForCard(card);
    String selectedPaymentMethod = availablePaymentMethods.contains(vm.selectedPaymentMethod)
        ? vm.selectedPaymentMethod
        : availablePaymentMethods.first;
    if (card.type == CardType.single) {
      final controller = TextEditingController();

      showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (_, setModalState) {
              return AlertDialog(
                title: const Text('Añadir saldo'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Importe (€)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pagar con',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RadioGroup<String>(
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedPaymentMethod = value);
                      },
                      child: Column(
                        children: availablePaymentMethods.map((method) {
                          return RadioListTile<String>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: method,
                            title: Text(method),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirmar'),
                    onPressed: () async {
                      final amount = double.tryParse(controller.text) ?? 0;
                      if (amount > 0) {
                        vm.setSelectedPaymentMethod(selectedPaymentMethod);
                        await vm.rechargeCard(
                          card,
                          amount,
                          paymentMethod: selectedPaymentMethod,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saldo añadido con éxito ($selectedPaymentMethod)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    final amount = vm.getRechargeAmount(card);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setModalState) {
            return AlertDialog(
              title: Text('Renovar ${card.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Importe: ${amount.toStringAsFixed(2)} €'),
                  const SizedBox(height: 12),
                  const Text(
                    'Pagar con',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RadioGroup<String>(
                    groupValue: selectedPaymentMethod,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedPaymentMethod = value);
                    },
                    child: Column(
                        children: availablePaymentMethods.map((method) {
                        return RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: method,
                          title: Text(method),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                  onPressed: () async {
                    vm.setSelectedPaymentMethod(selectedPaymentMethod);
                    await vm.rechargeCard(
                      card,
                      amount,
                      paymentMethod: selectedPaymentMethod,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tarjeta renovada con éxito ($selectedPaymentMethod)'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}