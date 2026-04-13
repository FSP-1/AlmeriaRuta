import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/ticket_validation_flow_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../widgets/buy_ticket_widgets.dart';
import '../services/ticket_purchase_api_service.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class BuyTicketView extends StatefulWidget {
  final TicketViewModel? ticketViewModel;

  const BuyTicketView({super.key, this.ticketViewModel});

  @override
  State<BuyTicketView> createState() => _BuyTicketViewState();
}

class _BuyTicketViewState extends State<BuyTicketView> {
  final _recipientController = TextEditingController();
  final _purchaseApi = TicketPurchaseApiService();
  final _validationFlow = TicketValidationFlowService();
  late final TicketViewModel _ticketViewModel;
  late final bool _ownsTicketViewModel;
  bool _giftMode = false;

  @override
  void initState() {
    super.initState();
    _ticketViewModel = widget.ticketViewModel ?? TicketViewModel();
    _ownsTicketViewModel = widget.ticketViewModel == null;
    _ticketViewModel.loadTickets();
  }

  @override
  void dispose() {
    _recipientController.dispose();
    if (_ownsTicketViewModel) {
      _ticketViewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isRegisteredUser = auth.isAuthenticated && !auth.isGuest;

    return ChangeNotifierProvider.value(
      value: _ticketViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comprar billete'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Consumer<TicketViewModel>(
          builder: (context, vm, child) {
            if (!isRegisteredUser && _giftMode) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _giftMode = false;
                  _recipientController.clear();
                });
              });
            }

            if (!isRegisteredUser && vm.paymentMethod == 'Saldo') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                vm.setPaymentMethod('Google Pay');
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TicketTypeSelector(
                    selectedType: vm.selectedType,
                    onChanged: vm.setType,
                  ),
                  const SizedBox(height: 20),
                  GiftPurchaseSection(
                    isRegisteredUser: isRegisteredUser,
                    giftMode: _giftMode,
                    onGiftModeChanged: (value) {
                      setState(() {
                        _giftMode = value;
                      });
                    },
                    recipientController: _recipientController,
                  ),
                  const SizedBox(height: 24),

                  if (vm.selectedType == 'Multiple') ...[
                    QuantitySelector(
                      quantity: vm.quantity,
                      onDecrease: vm.quantity > 1 ? () => vm.setQuantity(vm.quantity - 1) : null,
                      onIncrease: vm.quantity < 99 ? () => vm.setQuantity(vm.quantity + 1) : null,
                    ),
                    const SizedBox(height: 24),
                  ],

                  PaymentMethodsSection(
                    isRegisteredUser: isRegisteredUser,
                    paymentMethod: vm.paymentMethod,
                    onPaymentMethodChanged: vm.setPaymentMethod,
                    balance: vm.balance,
                    hasInsufficientBalance: vm.hasInsufficientBalance,
                  ),
                  const SizedBox(height: 24),

                  if (isRegisteredUser && vm.paymentMethod == 'Saldo' && vm.hasInsufficientBalance) ...[
                    const InsufficientBalanceBanner(),
                    const SizedBox(height: 16),
                  ],

                  if (vm.errorMessage != null) ...[
                    PurchaseErrorBanner(
                      error: vm.errorMessage!,
                      onClear: vm.clearError,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TotalPriceCard(
                    totalPrice: vm.totalPrice,
                  ),
                  const SizedBox(height: 16),

                  BuyButton(
                    isLoading: vm.isLoading,
                    onPressed: () => _handlePurchase(context, vm),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, TicketViewModel vm) async {
    final auth = context.read<AuthViewModel>();
    final recipient = _recipientController.text.trim();

    if (_giftMode) {
      if (!auth.isAuthenticated || auth.isGuest || auth.token == null) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Necesitas iniciar sesión'),
            content: const Text('Para comprar un ticket a otro usuario debes iniciar sesión o registrarte.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        return;
      }

      if (recipient.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Introduce el email o usuario del destinatario')),
        );
        return;
      }

      try {
        await _purchaseApi.validateRecipient(
          token: auth.token!,
          recipientIdentifier: recipient,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se puede comprar: $e')),
        );
        return;
      }
    }

    final success = await vm.buyTicket(createLocalTicket: !_giftMode);
    if (!success || !context.mounted) {
      return;
    }

    if (_giftMode) {
      try {
        await _purchaseApi.notifyTicketPurchase(
          token: auth.token!,
          recipientIdentifier: recipient,
          type: vm.selectedType,
          quantity: vm.selectedType == 'Multiple' ? vm.quantity : 1,
          amount: vm.totalPrice,
          paymentMethod: vm.paymentMethod,
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Billete enviado a $recipient')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compra realizada, pero no se pudo notificar al destinatario: $e')),
        );
      }
      return;
    }

    final ticket = vm.tickets.last;

    final shouldValidate = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Compra completada'),
            content: const Text('¿Quieres validar o usar el billete ahora?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No, volver'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sí, validar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldValidate || !context.mounted) {
      return;
    }

    final result = await _validationFlow.openValidationFlow(
      context: context,
      ticket: ticket,
    );

    if (!context.mounted) return;

    if (result.wasUsed) {
      if (result.isExhausted) {
        await vm.useTicket(ticket.id);
      } else {
        await vm.persistTicketsState();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Billete validado')),
      );
    }
  }
}
