import 'package:flutter/material.dart';

import '../../../../shared/services/line_models.dart';
import '../../viewmodels/operario_viewmodel.dart';
import 'operario_view_utils.dart';

class OperarioNoticeCard extends StatelessWidget {
  final OperarioViewModel vm;
  final NoticeModel notice;

  const OperarioNoticeCard({
    super.key,
    required this.vm,
    required this.notice,
  });

  @override
  Widget build(BuildContext context) {
    final color = operarioTypeColor(notice.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(operarioTypeIcon(notice.type), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        notice.type,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(notice.message, style: const TextStyle(fontSize: 13.5)),
                const SizedBox(height: 6),
                Text(
                  operarioFormatDate(notice.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Desactivar aviso',
            onPressed: vm.loading
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);

                    await vm.deactivateNotice(notice.id);

                    if (!context.mounted) return;

                    if (vm.error != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(vm.error!)),
                      );
                    } else if (vm.successMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(vm.successMessage!)),
                      );
                    }
                  },
            icon: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
    );
  }
}
