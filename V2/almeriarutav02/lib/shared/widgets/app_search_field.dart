import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String>? onQuerySubmitted;
  final String hintText;
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    this.onQuerySubmitted,
    required this.hintText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onQueryChanged('');
                },
              ),
        border: const OutlineInputBorder(),
      ),
      onChanged: onQueryChanged,
      onSubmitted: onQuerySubmitted ?? onQueryChanged,
    );
  }
}