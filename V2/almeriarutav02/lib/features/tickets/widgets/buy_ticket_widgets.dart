import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class TicketTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const TicketTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            value: selectedType,
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
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class GiftPurchaseSection extends StatelessWidget {
  final bool isRegisteredUser;
  final bool giftMode;
  final ValueChanged<bool> onGiftModeChanged;
  final TextEditingController recipientController;

  const GiftPurchaseSection({
    super.key,
    required this.isRegisteredUser,
    required this.giftMode,
    required this.onGiftModeChanged,
    required this.recipientController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Comprar para otro usuario'),
          subtitle: Text(
            isRegisteredUser
                ? 'El destinatario recibirá una notificación en su cuenta.'
                : 'Disponible solo para cuentas registradas.',
          ),
          value: giftMode,
          onChanged: !isRegisteredUser ? null : onGiftModeChanged,
        ),
        if (giftMode) ...[
          const SizedBox(height: 8),
          TextField(
            controller: recipientController,
            decoration: const InputDecoration(
              labelText: 'Email o usuario del destinatario',
              border: OutlineInputBorder(),
              helperText: 'Debe estar registrado en la app',
            ),
          ),
        ],
      ],
    );
  }
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: onDecrease,
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
                quantity.toString(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
            IconButton(
              onPressed: onIncrease,
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.primaryRed,
            ),
          ],
        ),
      ],
    );
  }
}

class PaymentMethodsSection extends StatelessWidget {
  final bool isRegisteredUser;
  final String paymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final double balance;
  final bool hasInsufficientBalance;

  const PaymentMethodsSection({
    super.key,
    required this.isRegisteredUser,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.balance,
    required this.hasInsufficientBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                groupValue: paymentMethod,
                onChanged: onPaymentMethodChanged,
                icon: Icons.account_balance_wallet,
                title: 'Saldo: ${balance.toStringAsFixed(2)} €',
                subtitle: hasInsufficientBalance ? 'Saldo insuficiente' : null,
              ),
            _PaymentOption(
              value: 'Google Pay',
              groupValue: paymentMethod,
              onChanged: onPaymentMethodChanged,
              icon: Icons.android,
              title: 'Google Pay',
            ),
            _PaymentOption(
              value: 'Apple Pay',
              groupValue: paymentMethod,
              onChanged: onPaymentMethodChanged,
              icon: Icons.apple,
              title: 'Apple Pay',
            ),
            _PaymentOption(
              value: 'Visa',
              groupValue: paymentMethod,
              onChanged: onPaymentMethodChanged,
              icon: Icons.credit_card,
              title: 'Visa',
            ),
          ],
        ),
      ],
    );
  }
}

class InsufficientBalanceBanner extends StatelessWidget {
  const InsufficientBalanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class PurchaseErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onClear;

  const PurchaseErrorBanner({
    super.key,
    required this.error,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class TotalPriceCard extends StatelessWidget {
  final double totalPrice;

  const TotalPriceCard({
    super.key,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Total: ${totalPrice.toStringAsFixed(2)} €',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryRed,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BuyButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const BuyButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
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
