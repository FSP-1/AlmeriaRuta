import 'package:flutter/material.dart';

import '../../models/filter_mode.dart';
import '../../viewmodels/map_viewmodel.dart';
import '../../../../shared/services/line_search_utils.dart';
import '../../../../shared/widgets/app_search_field.dart';

Future<void> showLineSelectorSheet({
  required BuildContext context,
  required MapViewModel mapViewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (_) => _LineSelectorSheet(mapViewModel: mapViewModel),
  );
}

class _LineSelectorSheet extends StatefulWidget {
  final MapViewModel mapViewModel;

  const _LineSelectorSheet({required this.mapViewModel});

  @override
  State<_LineSelectorSheet> createState() => _LineSelectorSheetState();
}

class _LineSelectorSheetState extends State<_LineSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLines = LineSearchUtils.filterLines(
      widget.mapViewModel.lines,
      _query,
      stopMatcher: (lineId, normalizedQuery) {
        return widget.mapViewModel.stops.any(
          (stop) =>
              stop.lineIds.contains(lineId) &&
              LineSearchUtils.normalizeText(stop.name).contains(normalizedQuery),
        );
      },
    );

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'Filtrar por línea',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppSearchField(
                controller: _searchController,
                autofocus: true,
                query: _query,
                hintText: 'Buscar línea por nombre o destino',
                onQueryChanged: (value) {
                  setState(() => _query = value);
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filteredLines.isEmpty
                  ? const Center(
                      child: Text('No hay líneas que coincidan'),
                    )
                  : ListView.builder(
                      itemCount: filteredLines.length,
                      itemBuilder: (context, index) {
                        final line = filteredLines[index];
                        return ListTile(
                          leading: const Icon(Icons.directions_bus, color: Colors.red),
                          title: Text('Línea ${line.name}'),
                          subtitle: Text(line.fullName),
                          onTap: () {
                            widget.mapViewModel.setFilter(MapFilter.line(line.id));
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
