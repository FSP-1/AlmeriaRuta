import 'package:flutter/material.dart';

import '../../home/views/widgets/coming_soon_dialog.dart';
import '../models/coming_soon_mock.dart';

class ComingSoonMocksScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ComingSoonMock> mocks;

  const ComingSoonMocksScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.mocks,
  });

  void _showComingSoon(BuildContext context, String feature) {
    showComingSoonDialog(context, feature);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFB42318),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB42318).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB42318).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFFB42318)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFB42318),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...mocks.map(
            (mock) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: mock.color.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: mock.color.withValues(alpha: 0.15),
                  foregroundColor: mock.color,
                  child: Icon(mock.icon),
                ),
                title: Text(
                  mock.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(mock.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showComingSoon(context, mock.title),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
