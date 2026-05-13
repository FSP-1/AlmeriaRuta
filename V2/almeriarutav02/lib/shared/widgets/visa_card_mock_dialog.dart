import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class VisaCardMockDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _VisaCardMockDialogWidget(),
        ) ??
        false;

    return result;
  }
}

class _VisaCardMockDialogWidget extends StatefulWidget {
  const _VisaCardMockDialogWidget();

  @override
  State<_VisaCardMockDialogWidget> createState() => _VisaCardMockDialogWidgetState();
}

class _VisaCardMockDialogWidgetState extends State<_VisaCardMockDialogWidget> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tarjeta crédito (Visa)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                _VisaCardNumberTextInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Número de tarjeta',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: [
                      _ExpiryDateTextInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Caducidad',
                      hintText: 'MM/AA',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '***',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                LengthLimitingTextInputFormatter(26),
                FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZáéíóúÁÉÍÓÚñÑ ]")),
              ],
              decoration: const InputDecoration(
                labelText: 'Titular',
                hintText: 'Cualquier nombre',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Pagar'),
        ),
      ],
    );
  }
}

class _VisaCardNumberTextInputFormatter extends TextInputFormatter {
  const _VisaCardNumberTextInputFormatter();

  static const int _maxDigits = 16;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digitsOnly.length > _maxDigits ? digitsOnly.substring(0, _maxDigits) : digitsOnly;

    final buffer = StringBuffer();
    for (var i = 0; i < clamped.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clamped[i]);
    }

    final formatted = buffer.toString();

    // Keep cursor at end for simplicity (fast + stable).
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateTextInputFormatter extends TextInputFormatter {
  const _ExpiryDateTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;

    String formatted;
    if (clamped.length <= 2) {
      formatted = clamped;
    } else {
      formatted = '${clamped.substring(0, 2)}/${clamped.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
