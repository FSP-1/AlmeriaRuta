import 'package:flutter/material.dart';

class FilterOptionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const FilterOptionTile({
    super.key,
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : icon,
        color: selected ? color : Colors.grey,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
