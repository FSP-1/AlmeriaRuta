import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/recharge_viewmodel.dart';
import '../models/transport_card_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/visa_card_mock_dialog.dart';
import 'widgets/recharge_widgets.dart';
import '../requests/views/card_request_list_view.dart';

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
  static const _dismissKey = 'recharge_dismissed_card_chooser';

  bool _didShowInitialChooser = false;
  bool _hasChosenInitialCard = false;
  bool _dismissedInitialChooser = false;
  bool _loadedChooserState = false;

  String _paymentMethodLabel(String method) {
    if (method == 'Visa') return 'Visa crédito';
    return method;
  }

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  Future<void> _loadDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_dismissKey) ?? false;
    if (!mounted) return;
    setState(() {
      _dismissedInitialChooser = dismissed;
      _loadedChooserState = true;
    });
  }

  Future<void> _setDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, value);
    if (!mounted) return;
    setState(() {
      _dismissedInitialChooser = value;
    });
  }

  void _openCardRequestList(BuildContext context, RechargeViewModel vm, {bool markDismissOnReturn = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardRequestListView(
          token: widget.token,
          onSelectSaldo: () {
            final option = vm.cardOptions.firstWhere((o) => o.key == 'saldo_virtual');
            vm.setSelectedCardOption(option);
            _setDismissed(false);
            setState(() {
              _hasChosenInitialCard = true;
            });
            Navigator.pop(context);
            final saldoCard = vm.myCards.firstWhere(
              (card) => card.name == 'Tarjeta Saldo Virtual',
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showRechargeDialog(context, vm, saldoCard);
            });
          },
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      if (!_hasChosenInitialCard && markDismissOnReturn) {
        _setDismissed(true);
      }
    });
  }

  void _showInitialChooser(BuildContext context, RechargeViewModel vm) {
    if (_didShowInitialChooser) return;
    _didShowInitialChooser = true;
    _openCardRequestList(context, vm, markDismissOnReturn: true);
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
              builder: (context, vm, _) {
                return IconButton(
                  tooltip: 'Solicitar tarjeta',
                  icon: const Icon(Icons.add_card_outlined),
                  onPressed: () {
                    _openCardRequestList(context, vm);
                  },
                );
              },
            ),
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
            if (!_loadedChooserState) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!vm.profileResolved) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!vm.loadingProfile) {
              if (!_hasChosenInitialCard && vm.hasConfiguredCard) {
                _hasChosenInitialCard = true;
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (!vm.hasConfiguredCard && !_dismissedInitialChooser) {
                  _showInitialChooser(context, vm);
                }
              });
            }

            if (!_hasChosenInitialCard) {
              return _buildNoCardSelected(context, vm);
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
                            title: Text(_paymentMethodLabel(method)),
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
                        if (selectedPaymentMethod == 'Visa') {
                          final proceed = await VisaCardMockDialog.show(context);
                          if (!proceed) return;
                        }
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
                            content: Text(
                              'Saldo añadido con éxito (${_paymentMethodLabel(selectedPaymentMethod)})',
                            ),
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
                          title: Text(_paymentMethodLabel(method)),
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
                    if (selectedPaymentMethod == 'Visa') {
                      final proceed = await VisaCardMockDialog.show(context);
                      if (!proceed) return;
                    }
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
                        content: Text(
                          'Tarjeta renovada con éxito (${_paymentMethodLabel(selectedPaymentMethod)})',
                        ),
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

  Widget _buildNoCardSelected(BuildContext context, RechargeViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_off_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Aun no has seleccionado una tarjeta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _dismissedInitialChooser
                  ? 'Puedes solicitar una tarjeta cuando quieras.'
                  : 'Elige una tarjeta para empezar a recargar o solicitar una nueva.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCardRequestList(context, vm, markDismissOnReturn: true),
              icon: const Icon(Icons.add_card_outlined),
              label: const Text('Solicitar tarjeta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}