import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../controllers/play_history_controller.dart';
import '../controllers/auth_controller.dart';

/// State for play history management
class PlayHistoryState {
  final List<Song> recentlyPlayed;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const PlayHistoryState({
    this.recentlyPlayed = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  PlayHistoryState copyWith({
    List<Song>? recentlyPlayed,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return PlayHistoryState(
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory PlayHistoryState.initial() => const PlayHistoryState();
}

/// Controller for managing play history globally
class PlayHistoryGlobalController extends StateNotifier<PlayHistoryState> {
  final Ref _ref;

  PlayHistoryGlobalController(this._ref) : super(PlayHistoryState.initial());

  /// Load recently played songs
  Future<void> loadRecentlyPlayed() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use existing play history controller
      await _ref.read(playHistoryControllerProvider.notifier).loadRecentlyPlayed();
      
      final playHistoryState = _ref.read(playHistoryControllerProvider);
      
      // Convert PlayHistory to Song objects
      final songs = playHistoryState.recentlyPlayed.map((history) => Song(
        id: history.songId,
        title: history.songTitle ?? 'Unknown Song',
        artist: history.artistName ?? 'Unknown Artist',
        albumArtUrl: history.albumCoverUrl ?? '',
        durationInSeconds: 0, // Duration not needed for display
        albumName: 'Unknown Album',
      )).toList();
      
      state = state.copyWith(
        recentlyPlayed: songs,
        isLoading: false,
        lastUpdated: DateTime.now(),
        error: playHistoryState.error,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recently played: ${e.toString()}',
      );
    }
  }

  /// Refresh recently played (force reload)
  Future<void> refreshRecentlyPlayed() async {
    await loadRecentlyPlayed();
  }

  /// Add play history and optionally refresh
  Future<void> addPlayHistory(String songId, {
    int? durationSeconds, 
    bool completed = false,
    bool shouldRefresh = false,
  }) async {
    try {
      // Add to history using existing controller
      await _ref.read(playHistoryControllerProvider.notifier).addPlayHistory(
        songId,
        durationSeconds: durationSeconds,
        completed: completed,
      );

      // Refresh if requested
      if (shouldRefresh) {
        await refreshRecentlyPlayed();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add play history: ${e.toString()}',
      );
    }
  }

  /// Get recently played songs (up to limit)
  List<Song> getRecentlyPlayed({int limit = 20}) {
    return state.recentlyPlayed.take(limit).toList();
  }

  /// Check if song was recently played
  bool wasSongRecentlyPlayed(String songId) {
    return state.recentlyPlayed.any((song) => song.id == songId);
  }

  /// Get last played song
  Song? getLastPlayedSong() {
    return state.recentlyPlayed.isNotEmpty ? state.recentlyPlayed.first : null;
  }

  /// Notify that play history has been updated
  void notifyPlayHistoryUpdated() {
    state = state.copyWith(lastUpdated: DateTime.now());
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Clear all recently played
  void clearRecentlyPlayed() {
    state = state.copyWith(
      recentlyPlayed: [],
      lastUpdated: DateTime.now(),
    );
  }
}

/// Provider for PlayHistoryGlobalController
final playHistoryProvider = StateNotifierProvider<PlayHistoryGlobalController, PlayHistoryState>((ref) {
  return PlayHistoryGlobalController(ref);
});

/// Auto-refresh provider for play history (refreshes every 2 minutes)
final autoRefreshPlayHistoryProvider = StreamProvider<PlayHistoryState>((ref) {
  return Stream.periodic(const Duration(minutes: 2), (count) {
    // Only refresh if user is authenticated and we have initial data
    final authState = ref.read(authControllerProvider);
    final currentState = ref.read(playHistoryProvider);
    
    if (authState.isAuthenticated && currentState.error == null) {
      ref.read(playHistoryProvider.notifier).refreshRecentlyPlayed();
    }
    return ref.read(playHistoryProvider);
  });
});

/// Provider for easy access to recently played list
final recentlyPlayedListProvider = Provider<List<Song>>((ref) {
  return ref.watch(playHistoryProvider).recentlyPlayed;
});

/// Provider for limited recently played (for home screen)
final recentlyPlayedLimitedProvider = Provider.family<List<Song>, int>((ref, limit) {
  final playHistoryController = ref.watch(playHistoryProvider.notifier);
  return playHistoryController.getRecentlyPlayed(limit: limit);
}); 