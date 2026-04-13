import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../recharge/views/recharge_view.dart';
import '../../validation/views/validate_trip_view.dart';
import '../viewmodels/ticket_viewmodel.dart';
import 'buy_ticket_view.dart';

class TicketsHubView extends StatelessWidget {
  const TicketsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TicketViewModel(),
      child: const _TicketsHubContent(),
    );
  }
}

class _TicketsHubContent extends StatelessWidget {
  const _TicketsHubContent();

  @override
  Widget build(BuildContext context) {
    final ticketVm = context.watch<TicketViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final isRegisteredUser = authVm.isAuthenticated && !authVm.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetes y tarjeta'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: AppTheme.primaryRed.withValues(alpha: 0.08),
            child: const ListTile(
              leading: Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
              title: Text('Compra, recarga y valida desde aquí'),
              subtitle: Text('Todo lo relacionado con tickets y tarjeta en un único menú.'),
            ),
          ),
          const SizedBox(height: 16),
          _HubActionCard(
            icon: Icons.shopping_cart_checkout,
            title: 'Comprar billete',
            subtitle: 'Billete individual, múltiple o envío a otro usuario',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BuyTicketView(ticketViewModel: ticketVm),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubActionCard(
            icon: Icons.account_balance_wallet,
            title: 'Recargar tarjeta',
            subtitle: isRegisteredUser
                ? 'Gestiona el saldo y las tarjetas de transporte'
                : 'Disponible solo para usuarios registrados',
            color: Colors.orange,
            enabled: isRegisteredUser,
            onTap: isRegisteredUser
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RechargeView()),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 12),
          _HubActionCard(
            icon: Icons.qr_code_scanner,
            title: 'Validar / usar billete',
            subtitle: 'Selecciona un billete y úsalo cuando quieras',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketSelectionView(ticketViewModel: ticketVm),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (ticketVm.tickets.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: AppTheme.primaryRed),
                title: const Text('Billetes creados'),
                subtitle: Text('${ticketVm.tickets.length} billete(s) creados en esta sesión'),
              ),
            ),
        ],
      ),
    );
  }
}

class TicketSelectionView extends StatelessWidget {
  final TicketViewModel ticketViewModel;

  const TicketSelectionView({
    super.key,
    required this.ticketViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: ticketViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validar / usar billete'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Consumer<TicketViewModel>(
          builder: (context, vm, child) {
            if (vm.tickets.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay billetes creados en esta sesión',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.tickets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ticket = vm.tickets[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
                    title: Text('${ticket.type} - ${ticket.id}'),
                    subtitle: Text(
                      'Usos restantes: ${ticket.remainingUses}\nImporte: ${ticket.amount.toStringAsFixed(2)} €',
                    ),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final initialRemainingUses = ticket.remainingUses;

                        await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ValidateTripView(ticket: ticket),
                              ),
                            );

                        if (!context.mounted) return;

                        if (ticket.remainingUses < initialRemainingUses) {
                          if (ticket.remainingUses <= 0) {
                            vm.useTicket(ticket.id);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Billete usado')),
                          );
                        }
                      },
                      child: const Text('Usar'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _HubActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = enabled ? color : Colors.grey.shade700;

    return Card(
      elevation: 3,
      color: enabled ? null : Colors.grey.shade300,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: baseColor.withValues(alpha: 0.12),
          child: Icon(icon, color: baseColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: enabled ? null : Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? null : Colors.grey.shade700,
          ),
        ),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : Icon(
                Icons.lock,
                color: Colors.grey.shade700,
              ),
      ),
    );
  }
}