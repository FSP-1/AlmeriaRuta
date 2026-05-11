import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/map/views/optimized_map_view.dart';
import 'features/map/viewmodels/notices_viewmodel.dart';
import 'features/map/viewmodels/map_viewmodel.dart';
import 'features/map/tourism/viewmodels/tourism_viewmodel.dart';
import 'features/notifications/services/notification_scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rehidrata y reaplica avisos locales al iniciar la app.
  try {
    await NotificationSchedulerService().restoreFromStorage();
  } catch (_) {}

  runApp(const AlmeriaRutaApp());
}

class AlmeriaRutaApp extends StatelessWidget {
  const AlmeriaRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
        ChangeNotifierProvider(
          create: (_) => NoticesViewModel()..startAutoRefresh(),
        ),
        ChangeNotifierProvider(create: (_) => TourismViewModel()..load()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        home: const OptimizedMapView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}