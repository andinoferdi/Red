import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/song.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_options_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/music_player/music_player_screen.dart';
import '../screens/music_player/lyrics_screen.dart';
import '../screens/playlist/playlist_detail_screen.dart';
import '../screens/playlist/edit_playlist_screen.dart';
import '../screens/admin/duration_update_screen.dart';
import '../widgets/auth_wrapper.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(
  // Define a default transition for all routes
  replaceInRouteName: 'Screen,Route',
)
class AppRouter extends _$AppRouter {
  AppRouter({super.navigatorKey});

  // Consistent transition builder used across all routes
  static Widget _buildConsistentTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // Helper method for consistent manual navigation
  static PageRouteBuilder<T> createConsistentRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: _buildConsistentTransition,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
  @override
  RouteType get defaultRouteType => RouteType.custom(
    // Use consistent transition across all routes
    transitionsBuilder: _buildConsistentTransition,
    durationInMilliseconds: 200, // Consistent timing
  );

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: OnboardingRoute.page),
    AutoRoute(page: AuthOptionsRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: ForgotPasswordRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: ExploreRoute.page),
    AutoRoute(page: SearchRoute.page),
    AutoRoute(page: LibraryRoute.page),
    AutoRoute(page: StatsRoute.page),
    // Use consistent transition for fullscreen dialogs
    AutoRoute(
      page: MusicPlayerRoute.page, 
      fullscreenDialog: true,
      type: RouteType.custom(
        transitionsBuilder: _buildConsistentTransition,
        durationInMilliseconds: 200,
      ),
    ),
    AutoRoute(
      page: LyricsRoute.page, 
      fullscreenDialog: true,
      type: RouteType.custom(
        transitionsBuilder: _buildConsistentTransition,
        durationInMilliseconds: 200,
      ),
    ),
    AutoRoute(page: PlaylistDetailRoute.page),
    AutoRoute(page: EditPlaylistRoute.page),
    AutoRoute(page: DurationUpdateRoute.page),
    AutoRoute(page: AuthWrapperRoute.page),
  ];
}

// For convenience, this can be used to access the router from anywhere  
// Note: We create it later after navigatorKey is available

// Constants for named routes
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authOptions = '/auth-options';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
}


