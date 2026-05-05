import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/filter_mode.dart';
import '../viewmodels/map_viewmodel.dart';
import '../widgets/favorite_line_selector.dart';
import '../widgets/map_tutorial_dialog.dart';
import '../../../shared/services/onboarding_service.dart';

Future<void> maybeShowMapOnboarding(BuildContext context) async {
  final done = await OnboardingService.isDone();
  if (done || !context.mounted) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      showMapTutorialFlow(context: context, isFirstTime: true);
    }
  });
}

Future<void> showMapTutorialFlow({
  required BuildContext context,
  required bool isFirstTime,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !isFirstTime,
    builder: (dialogContext) => MapTutorialDialog(
      isFirstTime: isFirstTime,
      onComplete: () async {
        if (isFirstTime) {
          await OnboardingService.setDone();
          if (!context.mounted || !dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
          await showFavoriteLineSelector(context);
        } else {
          if (!dialogContext.mounted) return;
          Navigator.of(dialogContext).pop();
        }
      },
    ),
  );
}

Future<void> showFavoriteLineSelector(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    builder: (sheetContext) {
      final vm = context.read<MapViewModel>();
      return FavoriteLineSelector(
        lines: vm.lines,
        onLineSelected: (lineId) {
          vm.setFilter(MapFilter.line(lineId));
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      );
    },
  );
}
