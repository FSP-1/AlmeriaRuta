import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../viewmodels/validation_viewmodel.dart';
import '../models/validation_model.dart';
import '../../tickets/models/ticket_model.dart';
import '../../../core/theme/app_theme.dart';

class ValidateTripView extends StatelessWidget {
  final TicketModel ticket;

  const ValidateTripView({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ValidationViewModel()..setTicket(ticket),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Validar viaje"),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Consumer<ValidationViewModel>(
          builder: (_, vm, __) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: "${ticket.id}|${ticket.type}",
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    "Título: ${ticket.type}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "ID: ${ticket.id}",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (ticket.type == 'Multiple')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Viajes restantes: ${vm.currentTicket?.remainingUses ?? ticket.remainingUses}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Botón validar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        "Validar ahora",
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: vm.loading || (vm.currentTicket?.remainingUses ?? ticket.remainingUses) <= 0
                          ? null
                          : () async {
                              await vm.validate(
                                ticketId: ticket.id,
                                type: ticket.type,
                              );

                              if (!context.mounted) return;

                              final remainingUses = vm.currentTicket?.remainingUses ?? ticket.remainingUses;
                              if (vm.result?.isValid == true && remainingUses <= 0) {
                                Navigator.of(context).pop(true);
                              }
                            },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Loading
                  if (vm.loading)
                    const CircularProgressIndicator(
                      color: AppTheme.primaryRed,
                    ),

                  // Resultado
                  if (vm.result != null) _ResultCard(vm.result!),

                  // Error
                  if (vm.error != null)
                    Container(
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
                          Text(
                            vm.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
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
}

class _ResultCard extends StatelessWidget {
  final ValidationModel result;

  const _ResultCard(this.result);

  @override
  Widget build(BuildContext context) {
    final color = result.isValid ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.message,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: "Línea", value: result.line),
            _InfoRow(label: "Bus", value: result.busId),
            _InfoRow(
              label: "Fecha",
              value: "${result.date.day.toString().padLeft(2, '0')}/${result.date.month.toString().padLeft(2, '0')}/${result.date.year} ${result.date.hour.toString().padLeft(2, '0')}:${result.date.minute.toString().padLeft(2, '0')}",
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}