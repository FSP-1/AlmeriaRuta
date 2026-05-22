import 'package:flutter/material.dart';

import '../data/card_request_catalog.dart';
import '../models/card_request_info.dart';
import 'card_request_stepper_view.dart';
import 'card_request_status_view.dart';

class CardRequestListView extends StatelessWidget {
  final VoidCallback onSelectSaldo;
  final String? token;

  const CardRequestListView({
    super.key,
    required this.onSelectSaldo,
    required this.token,
  });

  void _openRequest(BuildContext context, CardRequestInfo info) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardRequestStepperView(info: info, token: token),
      ),
    );
  }

  void _openStatus(BuildContext context) {
    final authToken = token;
    if (authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesion para ver solicitudes.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardRequestStatusView(token: authToken),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar tarjeta'),
        backgroundColor: const Color(0xFFB42318),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB42318).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB42318).withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Elige la tarjeta que deseas. Te pediremos datos y documentos segun el tipo.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openStatus(context),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Mis solicitudes'),
            ),
          ),
          const SizedBox(height: 8),
          _buildSaldoCard(context),
          const SizedBox(height: 12),
          ...cardRequestCatalog.map((info) => _buildCardItem(context, info)),
        ],
      ),
    );
  }

  Widget _buildSaldoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          foregroundColor: Colors.green,
          child: const Icon(Icons.account_balance_wallet_outlined),
        ),
        title: const Text(
          'Tarjeta Saldo Virtual',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: const Text('Recarga libre para viajes puntuales.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onSelectSaldo,
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, CardRequestInfo info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: info.color.withValues(alpha: 0.15),
          foregroundColor: info.color,
          child: Icon(info.icon),
        ),
        title: Text(
          info.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${info.shortDescription}\n${info.priceLabel}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openRequest(context, info),
      ),
    );
  }
}
