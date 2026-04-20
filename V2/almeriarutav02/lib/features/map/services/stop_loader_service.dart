import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';

class StopLoaderService {
  final BusApiService _api;

  StopLoaderService({BusApiService? api}) : _api = api ?? BusApiService();

  /// Loads all lines and deduplicates stops across lines in parallel.
  Future<({List<LineModel> lines, List<StopModel> stops})> load() async {
    final lines = await _api.getLines();
    final uniqueStops = <String, StopModel>{};

    final entries = await Future.wait(
      lines.map((line) async {
        final stops = await _api.getLineStops(line.id);
        return MapEntry(line.id, stops);
      }),
    );

    for (final entry in entries) {
      final lineId = entry.key;
      for (final stop in entry.value) {
        if (uniqueStops.containsKey(stop.id)) {
          uniqueStops[stop.id] = uniqueStops[stop.id]!.copyWith(
            lineIds: {...uniqueStops[stop.id]!.lineIds, lineId},
          );
        } else {
          uniqueStops[stop.id] = stop.copyWith(
            lineIds: stop.lineIds.isEmpty ? {lineId} : stop.lineIds,
          );
        }
      }
    }

    return (lines: lines, stops: uniqueStops.values.toList());
  }
}
