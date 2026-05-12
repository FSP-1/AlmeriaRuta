import '../../../shared/services/bus_api_service.dart';
import '../../../shared/services/line_models.dart';

class StopLoaderService {
  final BusApiService _api;

  StopLoaderService({BusApiService? api}) : _api = api ?? BusApiService();

  /// Loads all lines and deduplicates stops across lines in parallel.
  Future<({List<LineModel> lines, List<StopModel> stops})> load() async {
    final lines = await _api.getLines();
    final allStops = <StopModel>[];
    final lineIdsByStopId = <String, Set<String>>{};

    final entries = await Future.wait(
      lines.map((line) async {
        final stops = await _api.getLineStops(line.id);
        return MapEntry(line.id, stops);
      }),
    );

    for (final entry in entries) {
      final lineId = entry.key;
      for (final stop in entry.value) {
        final ids = lineIdsByStopId.putIfAbsent(stop.id, () => <String>{});
        ids.add(lineId);
        allStops.add(stop.copyWith(lineIds: ids));
      }
    }

    return (lines: lines, stops: allStops);
  }
}
