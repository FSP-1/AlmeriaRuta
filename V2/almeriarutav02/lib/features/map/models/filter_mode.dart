enum FilterMode {
  nearby,  // Paradas cercanas (< 800m)
  all,     // Todas las paradas de todas las líneas
  line,    // Paradas de una línea específica
}

class MapFilter {
  final FilterMode mode;
  final String? lineId;
  
  const MapFilter({
    required this.mode,
    this.lineId,
  });
  
  const MapFilter.nearby() : mode = FilterMode.nearby, lineId = null;
  const MapFilter.all() : mode = FilterMode.all, lineId = null;
  MapFilter.line(String id) : mode = FilterMode.line, lineId = id;
  
  @override
  String toString() {
    switch (mode) {
      case FilterMode.nearby:
        return 'Cercanas';
      case FilterMode.all:
        return 'Todas';
      case FilterMode.line:
        return lineId ?? 'Línea';
    }
  }
}
