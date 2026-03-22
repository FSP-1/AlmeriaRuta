class ArrivalService {
  static const int baseMinutes = 15;

  static int getArrivalMinutes(String stopId, String lineId) {
    final now = DateTime.now();
    final totalMinutes = now.millisecondsSinceEpoch ~/ 60000;
    final offset = _generateOffset(stopId, lineId);

    final mod = (totalMinutes + offset) % baseMinutes;
    final remaining = baseMinutes - mod;

    return remaining == 0 ? baseMinutes : remaining;
  }

  static String formatArrivalLabel(int minutes) {
    if (minutes <= 1) return 'Llegando';
    if (minutes <= 3) return 'Inminente';
    return '$minutes min';
  }

  static int _generateOffset(String stopId, String lineId) {
    final hash = Object.hash(stopId, lineId);
    return hash.abs() % 4; // 0..3 min de desfase
  }
}
