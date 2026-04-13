import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/ticket_validation_flow_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../notifications/models/user_notification.dart';
import '../models/ticket_model.dart';
import '../viewmodels/ticket_viewmodel.dart';
import '../widgets/ticket_selection_widgets.dart';
import '../widgets/tickets_hub_widgets.dart';

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

            return TicketSelectionList(
              loadingRemoteTickets: _loadingRemoteTickets,
              remoteOnlyNotifications: remoteOnlyNotifications,
              localTickets: vm.tickets,
              onUseRemoteTicket: (notification) => _openRemoteTicketFromNotification(
                vm,
                notification,
              ),
              onUseLocalTicket: (ticket) => _openLocalTicket(vm, ticket),
            );
          },
        ),
      ),
    );
  }
}
