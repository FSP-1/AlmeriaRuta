import '../../../shared/services/line_models.dart';

class StopPopupModel {
  final StopModel stop;
  final String zoneName;
  final List<LineModel> passingLines;

  const StopPopupModel({
    required this.stop,
    required this.zoneName,
    required this.passingLines,
  });
}
