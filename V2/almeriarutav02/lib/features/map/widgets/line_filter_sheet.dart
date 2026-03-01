import 'package:flutter/material.dart';
import '../viewmodels/map_viewmodel.dart';
import '../models/filter_mode.dart';
import '../../../core/theme/app_theme.dart';

class LineFilterSheet extends StatefulWidget {
  final MapViewModel mapViewModel;

  const LineFilterSheet({
    super.key,
    required this.mapViewModel,
  });

  @override
  State<LineFilterSheet> createState() => _LineFilterSheetState();
}

class _LineFilterSheetState extends State<LineFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalize(_query.trim());
    final filteredLines = widget.mapViewModel.lines.where((line) {
      if (normalizedQuery.isEmpty) return true;

      final matchesLineInfo =
          _normalize(line.name).contains(normalizedQuery) ||
          _normalize(line.fullName).contains(normalizedQuery) ||
          _normalize(line.description).contains(normalizedQuery);

      if (matchesLineInfo) return true;

      final matchesStops = widget.mapViewModel.stops.any(
        (stop) =>
            stop.lineIds.contains(line.id) &&
            _normalize(stop.name).contains(normalizedQuery),
      );

      return matchesStops;
    }).toList();

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
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar línea por nombre o destino',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
                onSubmitted: (value) {
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
                          leading: const Icon(
                            Icons.directions_bus,
                            color: AppTheme.primaryRed,
                          ),
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
