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
        await _pickArrivalLineForStop(context, stopId: chosen.id);
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
      await _pickArrivalLineForStop(
        context,
        stopId: chosenStop.id,
        preferredLineId: chosenLine.id,
      );
    }
  }

  static Future<void> _pickArrivalLineForStop(
    BuildContext context, {
    required String stopId,
    String? preferredLineId,
  }) async {
    final vm = context.read<NotificationsViewModel>();

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

    final candidateLines = lines.where((line) {
      return line.stops.any((stop) => stop.id == stopId);
    }).toList();

    final linesToShow = candidateLines.isNotEmpty ? candidateLines : lines;
    final nameById = {for (final l in linesToShow) l.id: l.name};
    final subtitleById = {
      for (final l in linesToShow)
        l.id: '${l.firstService} - ${l.lastService} · ${l.frequency}'
    };

    final chosenId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          children: [
            const ListTile(title: Text('Elegir linea para el aviso')),
            if (candidateLines.isEmpty)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No se pudo resolver la linea por parada. Elige una manualmente.'),
              ),
            for (final line in linesToShow)
              ListTile(
                leading: const Icon(Icons.directions_bus),
                title: Text('${line.name} - ${line.fullName}'.trim()),
                subtitle: Text(subtitleById[line.id] ?? ''),
                trailing: (preferredLineId != null && line.id == preferredLineId)
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, line.id),
              ),
          ],
        );
      },
    );

    if (!context.mounted || chosenId == null) return;
    vm.setArrivalLine(id: chosenId, name: nameById[chosenId] ?? chosenId);
  }
}

enum _StopPickSource { favorites, byLine }

class _StopChoice {
  final String id;
  final String name;

  const _StopChoice({required this.id, required this.name});
}
