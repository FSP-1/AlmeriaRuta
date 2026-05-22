import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/card_request_record.dart';
import '../services/card_request_service.dart';

class CardRequestStatusView extends StatefulWidget {
  final String token;

  const CardRequestStatusView({
    super.key,
    required this.token,
  });

  @override
  State<CardRequestStatusView> createState() => _CardRequestStatusViewState();
}

class _CardRequestStatusViewState extends State<CardRequestStatusView> {
  bool _loading = true;
  String? _error;
  List<CardRequestRecord> _requests = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final requests = await CardRequestService().listMy(token: widget.token);
      if (!mounted) return;
      setState(() {
        _requests = requests;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _requests.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: _requests.map(_buildItem).toList(),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(_error ?? 'No se pudo cargar.'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _load,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('No tienes solicitudes registradas.'),
    );
  }

  Widget _buildItem(CardRequestRecord request) {
    final color = switch (request.status) {
      'approved' => Colors.green,
      'denied' => Colors.red,
      _ => Colors.orange,
    };

    final statusLabel = switch (request.status) {
      'approved' => 'Aprobada',
      'denied' => 'Denegada',
      _ => 'Pendiente',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        title: Text(request.cardId),
        subtitle: request.decisionReason != null
            ? Text(request.decisionReason!)
            : Text('Estado: $statusLabel'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
