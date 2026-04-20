import 'package:flutter/material.dart';
import '../viewmodels/map_viewmodel.dart';
import '../tourism/viewmodels/tourism_viewmodel.dart';
import '../widgets/map_filter_bar.dart';
import '../widgets/search_widget.dart';
import '../widgets/map_overlay_banners.dart';
import '../tourism/widgets/tourism_category_sheet.dart';

/// Builds overlay UI elements on the map (banners, filter bar, search).
class MapOverlaysBuilder {
  /// Builds the main filter bar for the map.
  static Widget buildFilterBar(
    MapViewModel mapViewModel,
    VoidCallback onOpenLineSelector,
  ) {
    return MapFilterBar(
      mapViewModel: mapViewModel,
      onOpenLineSelector: onOpenLineSelector,
    );
  }

  /// Builds the search widget overlay.
  static Widget buildSearchWidget(
    Function(dynamic) onLocationSelected,
  ) {
    return SearchWidget(
      onLocationSelected: onLocationSelected,
    );
  }

  /// Builds all positioned overlays (banners).
  static List<Widget> buildPositionedOverlays({
    required MapViewModel mapViewModel,
    required TourismViewModel tourismViewModel,
    required bool isFavoritesFilterEmpty,
    required bool isTouristBusRouteOnlyMode,
    required bool hasActiveZone,
    required VoidCallback onClearZoneFilter,
    required VoidCallback onOpenTourismSelector,
  }) {
    final overlays = <Widget>[];

    // Favorites empty banner
    if (isFavoritesFilterEmpty && !isTouristBusRouteOnlyMode) {
      overlays.add(
        const Positioned(
          top: 72,
          left: 16,
          right: 16,
          child: FavoritesEmptyBanner(),
        ),
      );
    }

    // Active zone banner
    if (hasActiveZone && !isTouristBusRouteOnlyMode) {
      overlays.add(
        Positioned(
          top: isFavoritesFilterEmpty ? 140 : 72,
          left: 16,
          right: 16,
          child: ActiveZoneBanner(
            zone: mapViewModel.activeZone!,
            onClear: onClearZoneFilter,
          ),
        ),
      );
    }

    // Tourism mode banner
    if (tourismViewModel.isEnabled && !isTouristBusRouteOnlyMode) {
      overlays.add(
        Positioned(
          top: hasActiveZone
              ? (isFavoritesFilterEmpty ? 234 : 166)
              : (isFavoritesFilterEmpty ? 140 : 72),
          left: 16,
          right: 16,
          child: TourismModeBanner(
            title: tourismViewModel.selectedCategory == null
                ? 'Turismo: todos'
                : 'Turismo: ${tourismCategoryLabel(tourismViewModel.selectedCategory!)}',
            onTune: onOpenTourismSelector,
          ),
        ),
      );
    }

    return overlays;
  }

  /// Builds search widget as positioned overlay.
  static Widget buildSearchOverlay(
    bool showSearch,
    Function(dynamic) onLocationSelected,
  ) {
    if (!showSearch) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SearchWidget(
        onLocationSelected: onLocationSelected,
      ),
    );
  }
}
