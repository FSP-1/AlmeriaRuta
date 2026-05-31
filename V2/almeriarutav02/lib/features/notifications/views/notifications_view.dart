import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
import 'notifications_stop_picker.dart';
import 'widgets/arrival_settings_card.dart';
import 'widgets/recharge_settings_card.dart';
import 'widgets/remote_inbox_section.dart';
import '../models/user_notification.dart';
import '../../validation/views/validate_trip_view.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();

    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(
        favoritesViewModel: FavoritesViewModel(),
        token: auth.token,
      )..load(),
      child: const _NotificationsViewBody(),
    );
  }
}

class _NotificationsViewBody extends StatelessWidget {
  const _NotificationsViewBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();
    final auth = context.watch<AuthViewModel>();
    final isRegisteredUser = auth.isAuthenticated && !auth.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (vm.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            vm.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      if (isRegisteredUser) ...[
                        RemoteInboxSection(
                          notifications: vm.remoteNotifications,
                          onOpenNotification: (notification) =>
                              _openNotification(context, vm, notification),
                          onDeleteNotification: (notification) =>
                              vm.deleteRemoteNotification(notification.id),
                        ),

                        const SizedBox(height: 16),

                        _sectionTitle('Recarga'),
                        RechargeSettingsCard(vm: vm),

                        const SizedBox(height: 12),
                      ],

                      _sectionTitle('Llegada de bus'),
                      ArrivalSettingsCard(
                        vm: vm,
                        onPickStop: () => NotificationsStopPicker.pickStop(context),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vm.hasPendingChanges
                            ? () async {
                                await vm.acceptChanges();
                                if (!context.mounted) return;
                                if (vm.error == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cambios guardados')),
                                  );
                                }
                              }
                            : null,
                        child: const Text('Aceptar'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    NotificationsViewModel vm,
    UserNotification notification,
  ) async {
    await vm.markRemoteNotificationAsRead(notification.id);
    if (!context.mounted) return;
    if (notification.ticket != null) {
      final exhausted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ValidateTripView(ticket: notification.ticket!),
        ),
      );

      if (!context.mounted) return;
      if (exhausted == true) {
        await vm.deleteRemoteNotification(notification.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket agotado. Notificación eliminada.')),
        );
      }
    }
  }
}
