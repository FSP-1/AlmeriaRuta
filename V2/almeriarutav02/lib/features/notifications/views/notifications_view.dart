import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../map/models/favorite_model.dart';
import '../../map/viewmodels/favorites_viewmodel.dart';
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
    final draft = vm.draft;

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
                        _sectionTitle('Bandeja personal'),
                        if (vm.remoteNotifications.isEmpty)
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.mail_outline),
                              title: Text('Sin notificaciones pendientes'),
                              subtitle: Text('Aquí aparecerán los tickets recibidos y otros avisos de cuenta.'),
                            ),
                          )
                        else
                          ...vm.remoteNotifications.map(
                            (notification) => Card(
                              child: ListTile(
                                onTap: () => _openNotification(context, vm, notification),
                                leading: Icon(
                                  notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                  color: notification.isRead ? Colors.grey : AppTheme.primaryRed,
                                ),
                                title: Text(notification.title),
                                subtitle: Text(
                                  '${notification.body}\n${_formatRemoteDate(notification.createdAt)}',
                                ),
                                isThreeLine: true,
                                trailing: notification.isRead
                                    ? const SizedBox.shrink()
                                    : TextButton(
                                        onPressed: () => _openNotification(context, vm, notification),
                                        child: const Text('Abrir'),
                                      ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        _sectionTitle('Recarga'),
                        Card(
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Recordatorio de mensual'),
                                subtitle: const Text('Aviso 3 días antes de caducar'),
                                value: draft.recharge.enabled,
                                onChanged: (v) => vm.setRechargeEnabled(v),
                              ),
                              ListTile(
                                title: const Text('Fecha de caducidad'),
                                subtitle: Text(_formatIsoDate(draft.recharge.monthlyExpiryDateIso) ?? 'Sin seleccionar'),
                                trailing: const Icon(Icons.event, color: AppTheme.lightRed),
                                enabled: draft.recharge.enabled,
                                onTap: !draft.recharge.enabled
                                    ? null
                                    : () async {
                                        final initial = _tryParseIsoDate(draft.recharge.monthlyExpiryDateIso) ?? DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: initial,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2100),
                                        );
                                        if (!context.mounted) return;
                                        vm.setMonthlyExpiryDate(picked);
                                      },
                              ),
                              ListTile(
                                title: const Text('Hora del aviso'),
                                subtitle: Text(_formatTime(draft.recharge.hour, draft.recharge.minute)),
                                trailing: const Icon(Icons.schedule, color: AppTheme.lightRed),
                                enabled: draft.recharge.enabled,
                                onTap: !draft.recharge.enabled
                                    ? null
                                    : () async {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                            hour: draft.recharge.hour,
                                            minute: draft.recharge.minute,
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        if (time != null) {
                                          vm.setRechargeTime(time);
                                        }
                                      },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      _sectionTitle('Llegada de bus'),
                      Card(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Aviso de llegada'),
                              subtitle: const Text('Cuando falten X minutos para llegar a una parada'),
                              value: draft.arrival.enabled,
                              onChanged: (v) => vm.setArrivalEnabled(v),
                            ),
                            ListTile(
                              title: const Text('Avisar con antelación'),
                              subtitle: Text('${draft.arrival.leadMinutes} minutos'),
                              enabled: draft.arrival.enabled,
                              trailing: DropdownButton<int>(
                                value: draft.arrival.leadMinutes,
                                onChanged: !draft.arrival.enabled
                                    ? null
                                    : (v) {
                                        if (v != null) vm.setArrivalLeadMinutes(v);
                                      },
                                items: const [1, 3, 5, 10, 15]
                                    .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                                    .toList(),
                              ),
                            ),
                            const Divider(height: 0),
                            ListTile(
                              title: const Text('Parada'),
                              subtitle: Text(_formatArrivalStopSubtitle(draft.arrival.stopName, draft.arrival.lineName) ?? 'Sin seleccionar'),
                              enabled: draft.arrival.enabled,
                              trailing: const Icon(Icons.location_on, color: AppTheme.lightRed),
                              onTap: !draft.arrival.enabled ? null : () => _pickStop(context),
                            ),
                            if (draft.arrival.enabled)
                              TextButton(
                                onPressed: vm.clearArrivalTarget,
                                child: const Text('Limpiar selección'),
                              ),
                          ],
                        ),
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

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String? _formatIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return iso;
  }

  String? _formatArrivalStopSubtitle(String? stopName, String? lineName) {
    if (stopName == null || stopName.isEmpty) return null;
    if (lineName == null || lineName.isEmpty) return stopName;
    return '$stopName · Línea: $lineName';
  }

  String _formatRemoteDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/${dateTime.year} $hour:$minute';
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

  DateTime? _tryParseIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parts = iso.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _pickStop(BuildContext context) async {
    final vm = context.read<NotificationsViewModel>();

    final source = await showModalBottomSheet<_StopPickSource>(
      context: context,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Elegir parada')),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('De favoritos'),
              onTap: () => Navigator.pop(sheetContext, _StopPickSource.favorites),
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Desde una línea'),
              onTap: () => Navigator.pop(sheetContext, _StopPickSource.byLine),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (source == null) return;

    if (source == _StopPickSource.favorites) {
      await vm.favorites.load();
      if (!context.mounted) return;
      final chosen = await showModalBottomSheet<FavoriteModel>(
        context: context,
        builder: (sheetContext) {
          final stops = vm.favorites.stops;
          return ListView(
            children: [
              const ListTile(title: Text('Elegir parada favorita')),
              for (final f in stops)
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(f.name),
                  onTap: () => Navigator.pop(sheetContext, f),
                ),
              if (stops.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay paradas favoritas.'),
                ),
            ],
          );
        },
      );
      if (!context.mounted) return;
      if (chosen != null) {
        vm.setArrivalStop(id: chosen.id, name: chosen.name);
        await _maybePickArrivalLineForStop(context, stopId: chosen.id);
      }
      return;
    }

    // Pick by line (only for browsing stops; the alert itself is NOT tied to a line).
    late final List<LineModel> lines;
    try {
      lines = await vm.getLines();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar líneas: $e')),
      );
      return;
    }
    if (!context.mounted) return;

    final chosenLine = await showModalBottomSheet<LineModel>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          children: [
            const ListTile(title: Text('Elegir línea')),
            for (final l in lines)
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text('${l.name} - ${l.fullName}'.trim()),
                onTap: () => Navigator.pop(sheetContext, l),
              ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (chosenLine == null) return;

    late final List<StopModel> stops;
    try {
      stops = await vm.getLineStops(chosenLine.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar paradas: $e')),
      );
      return;
    }
    if (!context.mounted) return;
    final chosenStop = await showModalBottomSheet<_StopChoice>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          children: [
            const ListTile(title: Text('Elegir parada de la línea')),
            for (final s in stops)
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(s.name),
                onTap: () => Navigator.pop(sheetContext, _StopChoice(id: s.id, name: s.name)),
              ),
          ],
        );
      },
    );

    if (!context.mounted) return;

    if (chosenStop != null) {
      vm.setArrivalStop(id: chosenStop.id, name: chosenStop.name);
      await _maybePickArrivalLineForStop(context, stopId: chosenStop.id, preferredLineId: chosenLine.id);
    }
  }

  Future<void> _maybePickArrivalLineForStop(
    BuildContext context, {
    required String stopId,
    String? preferredLineId,
  }) async {
    final vm = context.read<NotificationsViewModel>();

    // Query arrivals to infer which lines are relevant for this stop.
    Map<String, int> arrivals;
    try {
      arrivals = await vm.getStopArrivals(stopId, limit: 8);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    if (arrivals.isEmpty) {
      // If we can't infer, keep any previous line selection (user can re-pick stop later).
      return;
    }

    final lineIds = arrivals.keys.toList();
    if (lineIds.length == 1) {
      final id = lineIds.first;
      final name = await _resolveLineName(context, id);
      if (!context.mounted) return;
      vm.setArrivalLine(id: id, name: name);
      return;
    }

    // Multiple lines: ask user which one to track.
    final lines = await vm.getLines();
    if (!context.mounted) return;
    final nameById = {for (final l in lines) l.id: l.name};

    final sortedIds = [...lineIds]
      ..sort((a, b) => (arrivals[a] ?? 9999).compareTo(arrivals[b] ?? 9999));

    final chosenId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          children: [
            const ListTile(title: Text('Elegir línea para el aviso')),
            for (final id in sortedIds)
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text(nameById[id] ?? id),
                subtitle: Text('${arrivals[id]} min'),
                trailing: (preferredLineId != null && id == preferredLineId) ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(sheetContext, id),
              ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (chosenId == null) return;

    vm.setArrivalLine(id: chosenId, name: nameById[chosenId] ?? chosenId);
  }

  Future<String> _resolveLineName(BuildContext context, String lineId) async {
    final vm = context.read<NotificationsViewModel>();
    try {
      final lines = await vm.getLines();
      for (final l in lines) {
        if (l.id == lineId) return l.name;
      }
      return lineId;
    } catch (_) {
      return lineId;
    }
  }
}

enum _StopPickSource { favorites, byLine }

class _StopChoice {
  final String id;
  final String name;

  const _StopChoice({required this.id, required this.name});
}
