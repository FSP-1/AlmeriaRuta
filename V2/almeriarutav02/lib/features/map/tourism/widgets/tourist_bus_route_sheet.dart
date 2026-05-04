import 'package:flutter/material.dart';

import '../models/tourist_place.dart';
import '../utils/tourist_bus_route_planner.dart';
import 'tourist_bus_route_sheet/tourist_bus_route_sheet_content.dart';

/// Displays the complete bus route plan with step-by-step instructions.
Future<void> showTouristBusRouteSheet({
  required BuildContext context,
  required TouristPlace place,
  required TouristBusRoutePlan plan,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => TouristBusRouteSheetContent(
      place: place,
      plan: plan,
      onClose: () => Navigator.pop(sheetContext),
    ),
  );
}
