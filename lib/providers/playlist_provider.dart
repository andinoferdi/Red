import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../repositories/playlist_repository.dart';

/// Global playlist state using RecordModel for compatibility
class PlaylistState {
  final List<RecordModel> playlists;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const PlaylistState({
    this.playlists = const [],
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  PlaylistState copyWith({
    List<RecordModel>? playlists,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Global playlist controller with auto-refresh capabilities
class PlaylistController extends StateNotifier<PlaylistState> {
  final PlaylistRepository _repository;
  
  PlaylistController(this._repository) 
      : super(PlaylistState(lastUpdated: DateTime.now()));

  /// Load all playlists
  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final playlists = await _repository.getUserPlaylists();
      state = state.copyWith(
        playlists: playlists,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Refresh playlists (force reload)
  Future<void> refreshPlaylists() async {
    await loadPlaylists();
  }

  /// Notify that a playlist has been updated
  void notifyPlaylistUpdated() {
    // Trigger refresh by updating timestamp
    state = state.copyWith(lastUpdated: DateTime.now());
    // Auto-reload playlists
    loadPlaylists();
  }

  /// Notify that a specific playlist has been modified
  void notifyPlaylistModified(String playlistId) {
    notifyPlaylistUpdated();
  }

  /// Notify that songs have been added/removed from playlist
  void notifyPlaylistSongsChanged(String playlistId) {
    notifyPlaylistUpdated();
  }

  /// Get playlist by ID
  RecordModel? getPlaylistById(String id) {
    try {
      return state.playlists.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for playlist repository
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final pbService = PocketBaseService();
  return PlaylistRepository(pbService);
});

/// Global playlist provider - this is the main provider all screens will use
final playlistProvider = StateNotifierProvider<PlaylistController, PlaylistState>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistController(repository);
});

/// Auto-refresh provider that triggers refresh every 30 seconds
final autoRefreshProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 30), (count) => DateTime.now());
});

/// Combined provider that auto-refreshes playlists
final autoRefreshPlaylistProvider = Provider<PlaylistState>((ref) {
  // Watch the auto-refresh stream
  ref.watch(autoRefreshProvider);
  
  // Watch the main playlist state
  final playlistState = ref.watch(playlistProvider);
  
  // Trigger refresh if data is stale (older than 1 minute)
  final now = DateTime.now();
  final timeSinceUpdate = now.difference(playlistState.lastUpdated);
  
  if (timeSinceUpdate.inMinutes >= 1 && !playlistState.isLoading) {
    // Trigger refresh asynchronously
    Future.microtask(() {
      ref.read(playlistProvider.notifier).refreshPlaylists();
    });
  }
  
  return playlistState;
}); 