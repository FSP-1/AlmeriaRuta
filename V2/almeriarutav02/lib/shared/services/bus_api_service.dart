import 'dart:convert';
import 'package:http/http.dart' as http;
import 'line_models.dart';
import '../../core/constants/app_constants.dart';

class BusApiService {
  Future<List<LineModel>> getLines() async {
    final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/lines'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => LineModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar líneas');
  }
  
  Future<List<StopModel>> getLineStops(String lineId) async {
    final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/lines/$lineId/stops'));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => StopModel.fromJson(json)).toList();
    }
    throw Exception('Error al cargar paradas');
  }
}