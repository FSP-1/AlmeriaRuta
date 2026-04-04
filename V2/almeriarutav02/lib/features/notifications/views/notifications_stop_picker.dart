import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/line_models.dart';
import '../../map/models/favorite_model.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsStopPicker {
  static Future<void> pickStop(BuildContext context) async {
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
              title: const Text('Desde una linea'),
              onTap: () => Navigator.pop(sheetContext, _StopPickSource.byLine),
            ),
          ],
        );
      },
    );

    if (!context.mounted || source == null) return;

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

    late final List<LineModel> lines;
    try {
      lines = await vm.getLines();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar lineas: $e')),
      );
      return;
    }
    if (!context.mounted) return;

    final chosenLine = await showModalBottomSheet<LineModel>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          children: [
            const ListTile(title: Text('Elegir linea')),
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

    if (!context.mounted || chosenLine == null) return;

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
            const ListTile(title: Text('Elegir parada de la linea')),
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
      await _maybePickArrivalLineForStop(
        context,
        stopId: chosenStop.id,
        preferredLineId: chosenLine.id,
      );
    }
  }

  static Future<void> _maybePickArrivalLineForStop(
    BuildContext context, {
    required String stopId,
    String? preferredLineId,
  }) async {
    final vm = context.read<NotificationsViewModel>();

    Map<String, int> arrivals;
    try {
      arrivals = await vm.getStopArrivals(stopId, limit: 8);
    } catch (_) {
      return;
    }
    if (!context.mounted || arrivals.isEmpty) return;

    final lineIds = arrivals.keys.toList();
    if (lineIds.length == 1) {
      final id = lineIds.first;
      final name = await _resolveLineName(context, id);
      if (!context.mounted) return;
      vm.setArrivalLine(id: id, name: name);
      return;
    }

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
            const ListTile(title: Text('Elegir linea para el aviso')),
            for (final id in sortedIds)
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text(nameById[id] ?? id),
                subtitle: Text('${arrivals[id]} min'),
                trailing: (preferredLineId != null && id == preferredLineId)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, id),
              ),
          ],
        );
      },
    );

    if (!context.mounted || chosenId == null) return;
    vm.setArrivalLine(id: chosenId, name: nameById[chosenId] ?? chosenId);
  }

  static Future<String> _resolveLineName(BuildContext context, String lineId) async {
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
