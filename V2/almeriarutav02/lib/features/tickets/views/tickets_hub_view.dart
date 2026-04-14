import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/ticket_validation_flow_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../notifications/models/user_notification.dart';
import '../../recharge/views/recharge_view.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../widgets/tickets_hub_widgets.dart';
import 'buy_ticket_view.dart';
import 'ticket_selection_view.dart';

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
                      MaterialPageRoute(
                        builder: (_) => RechargeView(
                          token: authVm.token,
                          isGuest: authVm.isGuest,
                        ),
                      ),
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