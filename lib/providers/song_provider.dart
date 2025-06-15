import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../repositories/song_repository.dart';
import '../services/pocketbase_service.dart';

/// State for song management
class SongState {
  final List<Song> songs;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SongState({
    this.songs = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SongState copyWith({
    List<Song>? songs,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return SongState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory SongState.initial() => const SongState();
}

/// Controller for managing songs globally
class SongController extends StateNotifier<SongState> {
  final SongRepository _repository;

  SongController(this._repository, Ref ref) : super(SongState.initial());

  /// Load all songs
  Future<void> loadSongs() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      final songs = await _repository.getAllSongs();
      
      state = state.copyWith(
        songs: songs,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load songs: ${e.toString()}',
      );
    }
  }

  /// Refresh songs (force reload)
  Future<void> refreshSongs() async {
    // Clear repository cache first
    SongRepository.clearCache();
    await loadSongs();
  }

  /// Search songs locally (from loaded songs)
  List<Song> searchSongs(String query) {
    if (query.isEmpty) return state.songs;
    
    final lowercaseQuery = query.toLowerCase();
    return state.songs.where((song) {
      return song.title.toLowerCase().contains(lowercaseQuery) ||
             song.artist.toLowerCase().contains(lowercaseQuery) ||
             song.albumName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get song by ID from loaded songs
  Song? getSongById(String songId) {
    try {
      return state.songs.firstWhere((song) => song.id == songId);
    } catch (e) {
      return null;
    }
  }

  /// Get songs by artist
  List<Song> getSongsByArtist(String artistName) {
    return state.songs.where((song) => 
      song.artist.toLowerCase() == artistName.toLowerCase()
    ).toList();
  }

  /// Get songs by album
  List<Song> getSongsByAlbum(String albumName) {
    return state.songs.where((song) => 
      song.albumName.toLowerCase() == albumName.toLowerCase()
    ).toList();
  }

  /// Notify that songs have been updated (for external changes)
  void notifySongsUpdated() {
    state = state.copyWith(lastUpdated: DateTime.now());
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for song repository
final songRepositoryProvider = Provider<SongRepository>((ref) {
  final pbService = PocketBaseService();
  return SongRepository(pbService);
});

/// Provider for SongController
final songProvider = StateNotifierProvider<SongController, SongState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  return SongController(repository, ref);
});

/// Auto-refresh provider for songs (refreshes every 3 minutes)
final autoRefreshSongProvider = StreamProvider<SongState>((ref) {
  return Stream.periodic(const Duration(minutes: 3), (count) {
    // Only refresh if we have initial data and no error
    final currentState = ref.read(songProvider);
    if (currentState.songs.isNotEmpty && currentState.error == null) {
      ref.read(songProvider.notifier).refreshSongs();
    }
    return ref.read(songProvider);
  });
});

/// Provider for easy access to songs list
final songsListProvider = Provider<List<Song>>((ref) {
  return ref.watch(songProvider).songs;
});

/// Provider for search functionality
final songSearchProvider = Provider.family<List<Song>, String>((ref, query) {
  final songController = ref.watch(songProvider.notifier);
  return songController.searchSongs(query);
}); 