import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/play_history.dart';
import '../repositories/play_history_repository.dart';
import '../services/pocketbase_service.dart';
import 'auth_controller.dart';

/// State for play history management
class PlayHistoryState {
  final List<PlayHistory> recentlyPlayed;
  final bool isLoading;
  final String? error;

  const PlayHistoryState({
    this.recentlyPlayed = const [],
    this.isLoading = false,
    this.error,
  });

  PlayHistoryState copyWith({
    List<PlayHistory>? recentlyPlayed,
    bool? isLoading,
    String? error,
  }) {
    return PlayHistoryState(
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for PocketBase instance
final pocketBaseProvider = Provider((ref) {
  return PocketBaseService().pb;
});

/// Provider for play history repository
final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return PlayHistoryRepository(pb);
});

/// Controller for managing play history
class PlayHistoryController extends StateNotifier<PlayHistoryState> {
  final PlayHistoryRepository _repository;
  final Ref _ref;

  PlayHistoryController(this._repository, this._ref)
      : super(const PlayHistoryState());

  /// Load recently played songs for current user
  Future<void> loadRecentlyPlayed({int limit = 5}) async {
    try {
      final authState = _ref.read(authControllerProvider);
      
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(
          error: 'User not logged in',
          isLoading: false,
          recentlyPlayed: [],
        );
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      final userId = authState.user!.id;
      if (userId.isEmpty) {
        state = state.copyWith(
          error: 'Invalid user ID',
          isLoading: false,
          recentlyPlayed: [],
        );
        return;
      }

      final histories = await _repository.getRecentlyPlayed(userId, limit: limit);

      state = state.copyWith(
        recentlyPlayed: histories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load recently played: $e',
        isLoading: false,
        recentlyPlayed: [],
      );
    }
  }

  /// Add new play history entry
  Future<void> addPlayHistory(String songId, {int? durationSeconds, bool completed = false}) async {
    try {
      final authState = _ref.read(authControllerProvider);
      
      if (!authState.isAuthenticated || authState.user == null) {
        return;
      }

      await _repository.addPlayHistory(
        userId: authState.user!.id,
        songId: songId,
        durationSeconds: durationSeconds,
        completed: completed,
      );
      
      // Don't auto-reload to prevent jarring UX in home screen
      // Data will be refreshed when user navigates back to home or manually refreshes
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add play history: $e',
      );
    }
  }

  /// Add new play history entry and refresh data (for cases where immediate refresh is needed)
  Future<void> addPlayHistoryAndRefresh(String songId, {int? durationSeconds, bool completed = false}) async {
    await addPlayHistory(songId, durationSeconds: durationSeconds, completed: completed);
    await loadRecentlyPlayed();
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for PlayHistoryController
final playHistoryControllerProvider =
    StateNotifierProvider<PlayHistoryController, PlayHistoryState>((ref) {
  final repository = ref.watch(playHistoryRepositoryProvider);
  return PlayHistoryController(repository, ref);
});

/// Provider for recently played songs (easier to use in UI)
final recentlyPlayedProvider = Provider<List<PlayHistory>>((ref) {
  return ref.watch(playHistoryControllerProvider).recentlyPlayed;
});
