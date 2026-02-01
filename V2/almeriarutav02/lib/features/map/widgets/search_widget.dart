import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/location_model.dart';
import '../../../core/theme/app_theme.dart';

class SearchWidget extends StatefulWidget {
  final Function(LocationModel) onLocationSelected;

  const SearchWidget({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _controller = TextEditingController();
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Buscar dirección o barrio...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryRed),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _suggestions = []);
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: _onSearchChanged,
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: AppTheme.primaryRed),
                    title: Text(suggestion.name ?? 'Ubicación'),
                    subtitle: Text(
                      suggestion.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onLocationSelected(suggestion);
                      _controller.text = suggestion.name ?? suggestion.address;
                      setState(() => _suggestions = []);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final suggestions = await _searchLocation(query);
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<List<LocationModel>> _searchLocation(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?'
      'q=$query, Almería, España&'
      'format=json&'
      'limit=5&'
      'bounded=1&'
      'viewbox=-2.55,36.75,-2.35,36.90',
    );

    final response = await http.get(
      url,
      headers: {'User-Agent': 'AlmeriaRuta/1.0.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => LocationModel(
        latitude: double.parse(item['lat']),
        longitude: double.parse(item['lon']),
        address: item['display_name'],
        name: item['name'],
      )).toList();
    }

    return [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}