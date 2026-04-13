import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/ticket_validation_flow_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../notifications/models/user_notification.dart';
import '../../recharge/views/recharge_view.dart';
import '../models/ticket_model.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../widgets/tickets_hub_widgets.dart';
import 'buy_ticket_view.dart';

class TicketsHubView extends StatelessWidget {
  const TicketsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TicketViewModel()..loadTickets(),
      child: const _TicketsHubContent(),
    );
  }
}

class _TicketsHubContent extends StatefulWidget {
  const _TicketsHubContent();

  @override
  State<_TicketsHubContent> createState() => _TicketsHubContentState();
}

class _TicketsHubContentState extends State<_TicketsHubContent> {
  final TicketValidationFlowService _validationFlow = TicketValidationFlowService();
  List<UserNotification> _remoteTicketNotifications = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRemoteTicketNotifications();
    });
  }

  Future<void> _loadRemoteTicketNotifications() async {
    final auth = context.read<AuthViewModel>();

    try {
      final notifications = await _validationFlow.fetchActiveRemoteTicketNotifications(
        token: auth.token,
        isAuthenticated: auth.isAuthenticated,
        isGuest: auth.isGuest,
      );
      if (!mounted) return;
      setState(() {
        _remoteTicketNotifications = notifications;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remoteTicketNotifications = const [];
      });
    }
  }

  int _totalUnusedTickets(TicketViewModel ticketVm) {
    return _validationFlow.totalUnusedTickets(
      localTickets: ticketVm.tickets,
      remoteNotifications: _remoteTicketNotifications,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketVm = context.watch<TicketViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final isRegisteredUser = authVm.isAuthenticated && !authVm.isGuest;
    final totalUnusedTickets = _totalUnusedTickets(ticketVm);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billetes y tarjeta'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TicketsHubIntroCard(),
          const SizedBox(height: 16),
          HubActionCard(
            icon: Icons.shopping_cart_checkout,
            title: 'Comprar billete',
            subtitle: 'Billete individual, múltiple o envío a otro usuario',
            color: Colors.green,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BuyTicketView(ticketViewModel: ticketVm),
                ),
              );
              await _loadRemoteTicketNotifications();
            },
          ),
          const SizedBox(height: 12),
          HubActionCard(
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
          HubActionCard(
            icon: Icons.qr_code_scanner,
            title: 'Validar / usar billete',
            subtitle: 'Selecciona un billete y úsalo cuando quieras',
            color: Colors.blue,
            badgeCount: totalUnusedTickets,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketSelectionView(ticketViewModel: ticketVm),
                ),
              );
              await _loadRemoteTicketNotifications();
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

class TicketSelectionView extends StatefulWidget {
  final TicketViewModel ticketViewModel;

  const TicketSelectionView({
    super.key,
    required this.ticketViewModel,
  });

  @override
  State<TicketSelectionView> createState() => _TicketSelectionViewState();
}

class _TicketSelectionViewState extends State<TicketSelectionView> {
  final TicketValidationFlowService _validationFlow = TicketValidationFlowService();
  List<UserNotification> _remoteTicketNotifications = const [];
  bool _loadingRemoteTickets = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRemoteTicketNotifications();
    });
  }

  Future<void> _loadRemoteTicketNotifications() async {
    final auth = context.read<AuthViewModel>();

    setState(() {
      _loadingRemoteTickets = true;
    });

    try {
      final ticketNotifications = await _validationFlow.fetchActiveRemoteTicketNotifications(
        token: auth.token,
        isAuthenticated: auth.isAuthenticated,
        isGuest: auth.isGuest,
      );

      if (!mounted) return;
      setState(() {
        _remoteTicketNotifications = ticketNotifications;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _remoteTicketNotifications = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingRemoteTickets = false;
        });
      }
    }
  }

  Future<void> _openRemoteTicketFromNotification(
    TicketViewModel vm,
    UserNotification notification,
  ) async {
    final auth = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final token = auth.token;
    final ticket = notification.ticket;
    if (ticket == null) return;

    final result = await _validationFlow.openValidationFlow(
      context: context,
      ticket: ticket,
    );

    if (!mounted) return;

    if (result.wasUsed) {
      if (token != null) {
        try {
          await _validationFlow.markNotificationAsRead(
            token: token,
            notificationId: notification.id,
          );
        } catch (_) {
          // Ignore network errors and keep validation flow.
        }
      }

      if (result.isExhausted && token != null) {
        try {
          await _validationFlow.deleteNotification(
            token: token,
            notificationId: notification.id,
          );
        } catch (_) {
          // Keep UI flow even if backend deletion fails.
        }
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Billete usado')),
      );
    }

    await _loadRemoteTicketNotifications();
  }

  Future<void> _openLocalTicket(TicketViewModel vm, TicketModel ticket) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _validationFlow.openValidationFlow(
      context: context,
      ticket: ticket,
    );

    if (!mounted) return;

    if (result.wasUsed) {
      if (result.isExhausted) {
        await vm.useTicket(ticket.id);
      } else {
        await vm.persistTicketsState();
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Billete usado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.ticketViewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validar / usar billete'),
          backgroundColor: AppTheme.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Consumer<TicketViewModel>(
          builder: (context, vm, child) {
            final localIds = vm.tickets.map((t) => t.id).toSet();
            final remoteOnlyNotifications = _remoteTicketNotifications
                .where((n) => n.ticket != null && !localIds.contains(n.ticket!.id))
                .toList();
            final hasAnyTicket = vm.tickets.isNotEmpty || remoteOnlyNotifications.isNotEmpty;

            if (!hasAnyTicket && !_loadingRemoteTickets) {
              return const TicketSelectionEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loadingRemoteTickets)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                if (remoteOnlyNotifications.isNotEmpty) ...[
                  ...remoteOnlyNotifications.map(
                    (notification) {
                      final ticket = notification.ticket!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TicketUseCard(
                          leading: Icon(
                            notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                            color: notification.isRead ? Colors.grey : AppTheme.primaryRed,
                          ),
                          title: '${ticket.type} - ${ticket.id}',
                          subtitle:
                              '${notification.body}\nUsos restantes: ${ticket.remainingUses}\nImporte: ${ticket.amount.toStringAsFixed(2)} €',
                          onUse: () => _openRemoteTicketFromNotification(
                            vm,
                            notification,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                ...vm.tickets.map(
                  (ticket) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TicketUseCard(
                      leading: const Icon(Icons.confirmation_number, color: AppTheme.primaryRed),
                      title: '${ticket.type} - ${ticket.id}',
                      subtitle:
                          'Usos restantes: ${ticket.remainingUses}\nImporte: ${ticket.amount.toStringAsFixed(2)} €',
                      onUse: () => _openLocalTicket(vm, ticket),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}