import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../validation/views/validate_trip_view.dart';
import '../services/ticket_purchase_api_service.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class BuyTicketView extends StatefulWidget {
  const BuyTicketView({super.key});

  @override
  State<BuyTicketView> createState() => _BuyTicketViewState();
}

class _BuyTicketViewState extends State<BuyTicketView> {
  final _recipientController = TextEditingController();
  final _purchaseApi = TicketPurchaseApiService();
  bool _giftMode = false;

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final isRegisteredUser = auth.isAuthenticated && !auth.isGuest;

    return ChangeNotifierProvider(
      create: (_) => TicketViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comprar Ticket'),
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
                  const Text(
                    'Seleccionar billete',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: vm.selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'Individual',
                          child: Row(
                            children: [
                              Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
                              SizedBox(width: 8),
                              Text('Ticket individual - 1.05€'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Multiple',
                          child: Row(
                            children: [
                              Icon(Icons.group, color: AppTheme.primaryRed),
                              SizedBox(width: 8),
                              Text('Ticket múltiple - 1.05€'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => vm.setType(v!),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Comprar para otro usuario'),
                    subtitle: Text(
                      isRegisteredUser
                          ? 'El destinatario recibirá una notificación en su cuenta.'
                          : 'Disponible solo para cuentas registradas.',
                    ),
                    value: _giftMode,
                    onChanged: !isRegisteredUser
                        ? null
                        : (value) {
                            setState(() {
                              _giftMode = value;
                            });
                          },
                  ),
                  if (_giftMode) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Email o usuario del destinatario',
                        border: OutlineInputBorder(),
                        helperText: 'Debe estar registrado en la app',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (vm.selectedType == 'Multiple') ...[
                    const Text(
                      'Cantidad',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: vm.quantity > 1 ? () => vm.setQuantity(vm.quantity - 1) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.primaryRed,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vm.quantity.toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        IconButton(
                          onPressed: vm.quantity < 99 ? () => vm.setQuantity(vm.quantity + 1) : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.primaryRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text(
                    'Método de pago',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      if (isRegisteredUser)
                        _PaymentOption(
                          value: 'Saldo',
                          groupValue: vm.paymentMethod,
                          onChanged: vm.setPaymentMethod,
                          icon: Icons.account_balance_wallet,
                          title: 'Saldo: ${vm.balance.toStringAsFixed(2)} €',
                          subtitle: vm.hasInsufficientBalance ? 'Saldo insuficiente' : null,
                        ),
                      _PaymentOption(
                        value: 'Google Pay',
                        groupValue: vm.paymentMethod,
                        onChanged: vm.setPaymentMethod,
                        icon: Icons.android,
                        title: 'Google Pay',
                      ),
                      _PaymentOption(
                        value: 'Apple Pay',
                        groupValue: vm.paymentMethod,
                        onChanged: vm.setPaymentMethod,
                        icon: Icons.apple,
                        title: 'Apple Pay',
                      ),
                      _PaymentOption(
                        value: 'Visa',
                        groupValue: vm.paymentMethod,
                        onChanged: vm.setPaymentMethod,
                        icon: Icons.credit_card,
                        title: 'Visa',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (isRegisteredUser && vm.paymentMethod == 'Saldo' && vm.hasInsufficientBalance) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo insuficiente. Recarga tu tarjeta o selecciona otro método de pago.',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (vm.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            onPressed: vm.clearError,
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Total: ${vm.totalPrice.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: vm.isLoading ? null : () => _handlePurchase(context, vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Comprar',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
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
    }

    final success = await vm.buyTicket();
    if (!success || !context.mounted) {
      return;
    }

    final ticket = vm.tickets.last;

    if (_giftMode) {
      try {
        await _purchaseApi.notifyTicketPurchase(
          token: auth.token!,
          recipientIdentifier: recipient,
          type: ticket.type,
          quantity: ticket.quantity,
          amount: ticket.amount,
          paymentMethod: vm.paymentMethod,
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket enviado a $recipient')),
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ValidateTripView(
          ticket: ticket,
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final Function(String) onChanged;
  final IconData icon;
  final String title;
  final String? subtitle;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppTheme.primaryRed : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => onChanged(value),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppTheme.primaryRed : Colors.grey,
              width: 2,
            ),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}