// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AuthOptionsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthOptionsScreen(),
      );
    },
    AuthWrapperRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthWrapper(),
      );
    },
    DurationUpdateRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const DurationUpdateScreen(),
      );
    },
    EditPlaylistRoute.name: (routeData) {
      final args = routeData.argsAs<EditPlaylistRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: EditPlaylistScreen(
          key: args.key,
          playlist: args.playlist,
        ),
      );
    },
    ExploreRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ExploreScreen(),
      );
    },
    ForgotPasswordRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ForgotPasswordScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    LibraryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LibraryScreen(),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginScreen(),
      );
    },
    LyricsRoute.name: (routeData) {
      final args = routeData.argsAs<LyricsRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: LyricsScreen(
          key: args.key,
          song: args.song,
        ),
      );
    },
    MusicPlayerRoute.name: (routeData) {
      final args = routeData.argsAs<MusicPlayerRouteArgs>(
          orElse: () => const MusicPlayerRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: MusicPlayerScreen(
          song: args.song,
          key: args.key,
        ),
      );
    },
    OnboardingRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OnboardingScreen(),
      );
    },
    PlaylistDetailRoute.name: (routeData) {
      final args = routeData.argsAs<PlaylistDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: PlaylistDetailScreen(
          key: args.key,
          playlist: args.playlist,
          onPlaylistUpdated: args.onPlaylistUpdated,
        ),
      );
    },
    RegisterRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RegisterScreen(),
      );
    },
    SearchRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SearchScreen(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashScreen(),
      );
    },
    StatsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const StatsScreen(),
      );
    },
  };
}

/// generated route for
/// [AuthOptionsScreen]
class AuthOptionsRoute extends PageRouteInfo<void> {
  const AuthOptionsRoute({List<PageRouteInfo>? children})
      : super(
          AuthOptionsRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthOptionsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [AuthWrapper]
class AuthWrapperRoute extends PageRouteInfo<void> {
  const AuthWrapperRoute({List<PageRouteInfo>? children})
      : super(
          AuthWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthWrapperRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [DurationUpdateScreen]
class DurationUpdateRoute extends PageRouteInfo<void> {
  const DurationUpdateRoute({List<PageRouteInfo>? children})
      : super(
          DurationUpdateRoute.name,
          initialChildren: children,
        );

  static const String name = 'DurationUpdateRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [EditPlaylistScreen]
class EditPlaylistRoute extends PageRouteInfo<EditPlaylistRouteArgs> {
  EditPlaylistRoute({
    Key? key,
    required RecordModel playlist,
    List<PageRouteInfo>? children,
  }) : super(
          EditPlaylistRoute.name,
          args: EditPlaylistRouteArgs(
            key: key,
            playlist: playlist,
          ),
          initialChildren: children,
        );

  static const String name = 'EditPlaylistRoute';

  static const PageInfo<EditPlaylistRouteArgs> page =
      PageInfo<EditPlaylistRouteArgs>(name);
}

class EditPlaylistRouteArgs {
  const EditPlaylistRouteArgs({
    this.key,
    required this.playlist,
  });

  final Key? key;

  final RecordModel playlist;

  @override
  String toString() {
    return 'EditPlaylistRouteArgs{key: $key, playlist: $playlist}';
  }
}

/// generated route for
/// [ExploreScreen]
class ExploreRoute extends PageRouteInfo<void> {
  const ExploreRoute({List<PageRouteInfo>? children})
      : super(
          ExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'ExploreRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ForgotPasswordScreen]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
      : super(
          ForgotPasswordRoute.name,
          initialChildren: children,
        );

  static const String name = 'ForgotPasswordRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LibraryScreen]
class LibraryRoute extends PageRouteInfo<void> {
  const LibraryRoute({List<PageRouteInfo>? children})
      : super(
          LibraryRoute.name,
          initialChildren: children,
        );

  static const String name = 'LibraryRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LyricsScreen]
class LyricsRoute extends PageRouteInfo<LyricsRouteArgs> {
  LyricsRoute({
    Key? key,
    required Song song,
    List<PageRouteInfo>? children,
  }) : super(
          LyricsRoute.name,
          args: LyricsRouteArgs(
            key: key,
            song: song,
          ),
          initialChildren: children,
        );

  static const String name = 'LyricsRoute';

  static const PageInfo<LyricsRouteArgs> page = PageInfo<LyricsRouteArgs>(name);
}

class LyricsRouteArgs {
  const LyricsRouteArgs({
    this.key,
    required this.song,
  });

  final Key? key;

  final Song song;

  @override
  String toString() {
    return 'LyricsRouteArgs{key: $key, song: $song}';
  }
}

/// generated route for
/// [MusicPlayerScreen]
class MusicPlayerRoute extends PageRouteInfo<MusicPlayerRouteArgs> {
  MusicPlayerRoute({
    Song? song,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          MusicPlayerRoute.name,
          args: MusicPlayerRouteArgs(
            song: song,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MusicPlayerRoute';

  static const PageInfo<MusicPlayerRouteArgs> page =
      PageInfo<MusicPlayerRouteArgs>(name);
}

class MusicPlayerRouteArgs {
  const MusicPlayerRouteArgs({
    this.song,
    this.key,
  });

  final Song? song;

  final Key? key;

  @override
  String toString() {
    return 'MusicPlayerRouteArgs{song: $song, key: $key}';
  }
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [PlaylistDetailScreen]
class PlaylistDetailRoute extends PageRouteInfo<PlaylistDetailRouteArgs> {
  PlaylistDetailRoute({
    Key? key,
    required RecordModel playlist,
    void Function()? onPlaylistUpdated,
    List<PageRouteInfo>? children,
  }) : super(
          PlaylistDetailRoute.name,
          args: PlaylistDetailRouteArgs(
            key: key,
            playlist: playlist,
            onPlaylistUpdated: onPlaylistUpdated,
          ),
          initialChildren: children,
        );

  static const String name = 'PlaylistDetailRoute';

  static const PageInfo<PlaylistDetailRouteArgs> page =
      PageInfo<PlaylistDetailRouteArgs>(name);
}

class PlaylistDetailRouteArgs {
  const PlaylistDetailRouteArgs({
    this.key,
    required this.playlist,
    this.onPlaylistUpdated,
  });

  final Key? key;

  final RecordModel playlist;

  final void Function()? onPlaylistUpdated;

  @override
  String toString() {
    return 'PlaylistDetailRouteArgs{key: $key, playlist: $playlist, onPlaylistUpdated: $onPlaylistUpdated}';
  }
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SearchScreen]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [StatsScreen]
class StatsRoute extends PageRouteInfo<void> {
  const StatsRoute({List<PageRouteInfo>? children})
      : super(
          StatsRoute.name,
          initialChildren: children,
        );

  static const String name = 'StatsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}


