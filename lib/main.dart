import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'routes/app_router.dart';
import 'services/pocketbase_service.dart';
import 'core/di/service_locator.dart';
import 'controllers/auth_controller.dart';
import 'utils/theme.dart';

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global app router instance using the navigator key
final appRouter = AppRouter(navigatorKey: navigatorKey);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await setupServiceLocator();
  
  // Initialize PocketBase connection (this will also restore saved auth)
  await GetIt.I<PocketBaseService>().initialize();
  
  // Auto-update song durations on app startup (optional)
  // _autoUpdateDurationsOnStartup();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali aktif dari background
        _checkAuthOnResume();
        break;
      case AppLifecycleState.paused:
        // App masuk ke background
        break;
      case AppLifecycleState.inactive:
        // App inactive (misalnya ada notifikasi masuk)
        break;
      case AppLifecycleState.detached:
        // App akan ditutup
        break;
      case AppLifecycleState.hidden:
        // App tersembunyi
        break;
    }
  }

  void _checkAuthOnResume() async {
    try {
      // Re-check authentication status when app resumes
      final authController = ref.read(authControllerProvider.notifier);
      await authController.reinitializeAuth();
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = appRouter;
    
    return MaterialApp.router(
      title: 'RedRhythm',
      debugShowCheckedModeBanner: false,
      routerDelegate: router.delegate(),
      routeInformationParser: router.defaultRouteParser(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final double scaleFactor = mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.0);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      theme: AppTheme.theme,
    );
  }
}


