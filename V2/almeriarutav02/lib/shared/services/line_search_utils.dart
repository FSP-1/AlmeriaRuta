import 'line_models.dart';

typedef StopMatcher = bool Function(String lineId, String normalizedQuery);

class LineSearchUtils {
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  static List<LineModel> filterLines(
    List<LineModel> lines,
    String query, {
    StopMatcher? stopMatcher,
  }) {
    final normalizedQuery = normalizeText(query.trim());
    if (normalizedQuery.isEmpty) {
      return lines;
    }

    return lines.where((line) {
      final matchesLineInfo =
          normalizeText(line.name).contains(normalizedQuery) ||
          normalizeText(line.fullName).contains(normalizedQuery) ||
          normalizeText(line.description).contains(normalizedQuery);

      if (matchesLineInfo) {
        return true;
      }

      return stopMatcher?.call(line.id, normalizedQuery) ?? false;
    }).toList();
  }
}