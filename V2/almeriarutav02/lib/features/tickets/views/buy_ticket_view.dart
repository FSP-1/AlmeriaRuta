import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class BuyTicketView extends StatelessWidget {
  const BuyTicketView({super.key});

  @override
  Widget build(BuildContext context) {
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
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo de título
                  const Text(
                    'Tipo de título',
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
                      items: [
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
                        DropdownMenuItem(
                          value: 'Tarjeta',
                          child: Row(
                            children: [
                              Icon(Icons.credit_card, color: AppTheme.primaryRed),
                              SizedBox(width: 8),
                              Text('Tarjeta virtual - 10.00€'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => vm.setType(v!),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cantidad (solo para tickets múltiples)
                  if (vm.selectedType == 'Multiple') ...[
                    const Text(
                      'Cantidad',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: vm.quantity > 1
                              ? () => vm.setQuantity(vm.quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.primaryRed,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                          onPressed: vm.quantity < 99
                              ? () => vm.setQuantity(vm.quantity + 1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.primaryRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Método de pago
                  const Text(
                    'Método de pago',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
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

                  // Error message
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

                  const Spacer(),

                  // Precio total
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

                  // Botón comprar
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

  void _handlePurchase(BuildContext context, TicketViewModel vm) async {
    final success = await vm.buyTicket();
    
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Compra realizada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final Function(String) onChanged;
  final IconData icon;
  final String title;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: value == groupValue ? AppTheme.primaryRed : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        activeColor: AppTheme.primaryRed,
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryRed),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}