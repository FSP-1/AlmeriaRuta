import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/line_models.dart';

class FavoriteLineSelector extends StatelessWidget {
  final List<LineModel> lines;
  final Function(String) onLineSelected;

  const FavoriteLineSelector({
    super.key,
    required this.lines,
    required this.onLineSelected,
  });

  Color _parseLineColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppTheme.primaryRed;
    }
    
    try {
      String cleanColor = colorString.replaceFirst('#', '');
      
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      } else if (cleanColor.length != 8) {
        return AppTheme.primaryRed;
      }
      
      return Color(int.parse('0x$cleanColor'));
    } catch (e) {
      return AppTheme.primaryRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 500,
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.directions_bus, color: AppTheme.primaryRed),
              SizedBox(width: 8),
              Text(
                'Elige tu línea principal (opcional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'O simplemente cierra para ver paradas cercanas',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (_, i) {
                final line = lines[i];
                final lineColor = _parseLineColor(line.color);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      onLineSelected(line.id);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: lineColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                line.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Frecuencia: ${line.frequency}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
