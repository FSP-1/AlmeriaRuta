import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notices_viewmodel.dart';
import '../../../shared/services/line_models.dart';
import '../../../shared/services/notices_api_service.dart';

class NoticesMarqueeWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const NoticesMarqueeWidget({
    super.key,
    this.onTap,
  });

  @override
  State<NoticesMarqueeWidget> createState() => _NoticesMarqueeWidgetState();
}

class _NoticesMarqueeWidgetState extends State<NoticesMarqueeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final noticesVM = context.watch<NoticesViewModel>();

    if (noticesVM.hasNotices && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!noticesVM.hasNotices && _animationController.isAnimating) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoticesViewModel>(
      builder: (context, noticesVM, _) {
        if (!noticesVM.hasNotices) {
          return const SizedBox.shrink();
        }

        final noticesList = noticesVM.notices;
        final stopsList = noticesVM.disabledStops;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.amber.shade300, width: 2),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final offset = _animationController.value * 500;
                  return Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: _buildMarqueeContent(
                            noticesList,
                            stopsList,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: _buildMarqueeContent(
                            noticesList,
                            stopsList,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarqueeContent(
    List<NoticeModel> notices,
    List<DisabledStopModel> stops,
  ) {
    final textItems = <Widget>[];

    final orderedNotices = [...notices]
      ..sort((a, b) {
        final typeCmp = _typeOrder(a.type).compareTo(_typeOrder(b.type));
        if (typeCmp != 0) return typeCmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    for (var notice in orderedNotices) {
      final color = _typeColor(notice.type);
      textItems.add(
        Row(
          children: [
            Icon(
              _typeIcon(notice.type),
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              notice.title.isEmpty ? notice.message : notice.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      );
    }

    for (var stop in stops) {
      textItems.add(
        Row(
          children: [
            Icon(
              Icons.block,
              size: 14,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            Text(
              'Parada ${stop.stopName} deshabilitada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      );
    }

    return Row(children: textItems);
  }

  int _typeOrder(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return 0;
      case 'TURISMO':
        return 1;
      case 'LINEA':
        return 2;
      case 'PARADA':
        return 3;
      default:
        return 99;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return Icons.campaign_outlined;
      case 'TURISMO':
        return Icons.attractions_outlined;
      case 'LINEA':
        return Icons.route_outlined;
      case 'PARADA':
        return Icons.location_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return const Color(0xFF0EA5E9);
      case 'TURISMO':
        return const Color(0xFF16A34A);
      case 'LINEA':
        return const Color(0xFFDC2626);
      case 'PARADA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }
}

// Widget para mostrar un BottomSheet con el resumen de avisos
class NoticesSummarySheet extends StatelessWidget {
  final NoticesViewModel noticesVM;

  const NoticesSummarySheet({
    super.key,
    required this.noticesVM,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Avisos y Cambios',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (noticesVM.notices.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              'Avisos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...noticesVM.orderedNotices.map((notice) {
                          final color = _typeColor(notice.type);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withValues(alpha: 0.35)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(_typeIcon(notice.type), size: 18, color: color),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          notice.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        notice.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notice.message,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tipo: ${notice.type}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                if (noticesVM.disabledStops.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.block, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              'Paradas Deshabilitadas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...noticesVM.disabledStops.map((stop) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.stopName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Razón: ${stop.reason}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Desde: ${_formatDate(stop.disabledAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                if (noticesVM.notices.isEmpty && noticesVM.disabledStops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Colors.green.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Todo en orden',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay avisos ni cambios en este momento',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return Icons.campaign_outlined;
      case 'TURISMO':
        return Icons.attractions_outlined;
      case 'LINEA':
        return Icons.route_outlined;
      case 'PARADA':
        return Icons.location_on_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'GENERAL':
        return const Color(0xFF0EA5E9);
      case 'TURISMO':
        return const Color(0xFF16A34A);
      case 'LINEA':
        return const Color(0xFFDC2626);
      case 'PARADA':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }
}
