import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../recharge/requests/models/card_request_admin_record.dart';
import '../../../recharge/requests/services/card_request_service.dart';

class OperarioCardRequestsTab extends StatefulWidget {
  const OperarioCardRequestsTab({super.key});

  @override
  State<OperarioCardRequestsTab> createState() => _OperarioCardRequestsTabState();
}

class _OperarioCardRequestsTabState extends State<OperarioCardRequestsTab> {
  final CardRequestService _service = CardRequestService();
  bool _loading = true;
  String? _error;
  List<CardRequestAdminRecord> _requests = const [];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthViewModel>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Token requerido';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _service.listOperario(token: token, status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _requests = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _decide(CardRequestAdminRecord request, String status) async {
    final token = context.read<AuthViewModel>().token;
    if (token == null) return;

    String? reason;
    if (status == 'denied') {
      reason = await _askReason();
      if (reason == null) return;
    }

    try {
      await _service.decide(
        token: token,
        requestId: request.id,
        status: status,
        reason: reason,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Explica la razon del rechazo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    return (result != null && result.isNotEmpty) ? result : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _requests.isEmpty
              ? const Center(child: Text('No hay solicitudes registradas.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _requests.map(_buildRequestCard).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text('Filtro:'),
          const SizedBox(width: 12),
          DropdownButton<String?>(
            value: _statusFilter,
            onChanged: (value) {
              setState(() {
                _statusFilter = value;
              });
              _load();
            },
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 'pending', child: Text('Pendientes')),
              DropdownMenuItem(value: 'approved', child: Text('Aprobadas')),
              DropdownMenuItem(value: 'denied', child: Text('Denegadas')),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CardRequestAdminRecord request) {
    final statusColor = switch (request.status) {
      'approved' => Colors.green,
      'denied' => Colors.red,
      _ => Colors.orange,
    };

    final statusLabel = switch (request.status) {
      'approved' => 'Aprobada',
      'denied' => 'Denegada',
      _ => 'Pendiente',
    };

    final payload = request.payload ?? const {};
    final fullName = payload['fullName']?.toString() ?? 'Usuario ${request.userId}';
    final dni = payload['dni']?.toString() ?? '-';
    final email = payload['email']?.toString() ?? '-';
    final phone = payload['phone']?.toString() ?? '-';
    final address = payload['address']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(request.cardId),
        subtitle: Text('$fullName · $statusLabel'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DNI: $dni'),
                Text('Email: $email'),
                Text('Teléfono: $phone'),
                Text('Dirección: $address'),
                if (request.decisionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Motivo: ${request.decisionReason}'),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: request.status == 'pending'
                          ? () => _decide(request, 'approved')
                          : null,
                      child: const Text('Aprobar'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: request.status == 'pending'
                          ? () => _decide(request, 'denied')
                          : null,
                      child: const Text('Denegar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
