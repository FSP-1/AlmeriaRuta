import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recharge_viewmodel.dart';
import '../models/recharge_profile_model.dart';
import '../models/transport_card_model.dart';
import '../../../core/theme/app_theme.dart';

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
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Tarjetas activas',
                  onSelected: vm.toggleCardOption,
                  itemBuilder: (context) {
                    return vm.cardOptions
                        .where((option) => option.key != 'saldo_virtual')
                        .map((option) {
                      final selected = vm.selectedCardOption.key == option.key;
                      return PopupMenuItem<String>(
                        value: option.key,
                        child: Row(
                          children: [
                            Expanded(child: Text(option.title)),
                            if (selected)
                              const Icon(Icons.check, color: AppTheme.primaryRed),
                          ],
                        ),
                      );
                    }).toList();
                  },
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (vm.profileError != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      vm.profileError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (selectedTransportCard != null && vm.isExpiringSoon(selectedTransportCard)) ...[
                        _buildExpirationWarning(selectedTransportCard),
                        const SizedBox(height: 12),
                      ],
                      if (vm.hasSaldoCard)
                        _buildSaldoCard(context, vm, selectedCard)
                      else
                        _buildSaldoSetupCard(context, vm),
                      if (selectedTransportCard != null) ...[
                        const SizedBox(height: 12),
                        _buildTransportCard(context, vm, selectedTransportCard),
                      ] else ...[
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Activa una tarjeta adicional desde el menú superior derecho.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                      if (selectedCard.history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Primera recarga: introduce el importe que quieres añadir.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
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

  Widget _buildExpirationWarning(TransportCardModel card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Tarjeta próxima a caducar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${card.name}: ${_format(card.expirationDate!)}',
            style: TextStyle(color: Colors.orange[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildSaldoSetupCard(BuildContext context, RechargeViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarjeta saldo no creada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('Crea tu tarjeta saldo para poder recargar y pagar billetes con saldo.'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final option = vm.cardOptions.firstWhere((o) => o.key == 'saldo_virtual');
                  vm.setSelectedCardOption(option);
                  final saldoCard = vm.myCards.firstWhere((c) => c.name == 'Tarjeta Saldo Virtual');
                  _showRechargeDialog(context, vm, saldoCard);
                },
                child: const Text('Crear tarjeta saldo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldoCard(BuildContext context, RechargeViewModel vm, card) {
    final expired = vm.isExpired(card);

    return Card(
      color: expired ? Colors.grey[300] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: expired ? Colors.grey : AppTheme.primaryRed,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tarjeta Saldo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Saldo actual: ${card.balance.toStringAsFixed(2)} €'),
            const SizedBox(height: 4),
            const Text(
              'Recarga libre para añadir saldo a tu tarjeta.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showRechargeDialog(context, vm, card),
                child: const Text('Añadir saldo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard(BuildContext context, RechargeViewModel vm, card) {
    final expired = vm.isExpired(card);
    final amount = vm.getRechargeAmount(card);

    return Card(
      color: expired ? Colors.grey[300] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: expired ? Colors.grey : AppTheme.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    card.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Importe fijo: ${amount.toStringAsFixed(2)} €'),
            const SizedBox(height: 4),
            Text(
              card.expirationDate != null
                  ? 'Caduca: ${_format(card.expirationDate!)}'
                  : 'Sin caducidad marcada',
              style: TextStyle(color: expired ? Colors.red : Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              card.type == CardType.monthly
                  ? 'Recarga mensual activa.'
                  : 'Recarga por usos o bonificación aplicada.',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: vm.canRecharge(card) ? AppTheme.primaryRed : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                onPressed: vm.canRecharge(card)
                    ? () => _showRechargeDialog(context, vm, card)
                    : null,
                child: const Text('Renovar'),
              ),
            ),
          ],
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