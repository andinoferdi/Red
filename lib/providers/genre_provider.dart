import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/genre_model.dart';
import '../controllers/genre_controller.dart';

/// State for genre management
class GenreState {
  final List<GenreModel> genres;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const GenreState({
    this.genres = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  GenreState copyWith({
    List<GenreModel>? genres,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return GenreState(
      genres: genres ?? this.genres,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory GenreState.initial() => const GenreState();
}

/// Controller for managing genres globally
class GenreGlobalController extends StateNotifier<GenreState> {
  final Ref _ref;

  GenreGlobalController(this._ref) : super(GenreState.initial());

  /// Load all genres
  Future<void> loadGenres() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use existing genre controller
      await _ref.read(genreControllerProvider.notifier).loadGenres();
      
      final genreControllerState = _ref.read(genreControllerProvider);
      
      state = state.copyWith(
        genres: genreControllerState.genres,
        isLoading: false,
        lastUpdated: DateTime.now(),
        error: genreControllerState.error,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load genres: ${e.toString()}',
      );
    }
  }

  /// Refresh genres (force reload)
  Future<void> refreshGenres() async {
    await loadGenres();
  }

  /// Get genre by ID
  GenreModel? getGenreById(String genreId) {
    try {
      return state.genres.firstWhere((genre) => genre.id == genreId);
    } catch (e) {
      return null;
    }
  }

  /// Get genre by name
  GenreModel? getGenreByName(String genreName) {
    try {
      return state.genres.firstWhere((genre) => 
        genre.name.toLowerCase() == genreName.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }

  /// Search genres by name
  List<GenreModel> searchGenres(String query) {
    if (query.isEmpty) return state.genres;
    
    final lowercaseQuery = query.toLowerCase();
    return state.genres.where((genre) {
      return genre.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get popular genres (sorted by some criteria)
  List<GenreModel> getPopularGenres({int limit = 10}) {
    // For now, just return first N genres
    // In the future, this could be sorted by song count or popularity
    return state.genres.take(limit).toList();
  }

  /// Get all genre names
  List<String> getGenreNames() {
    return state.genres.map((genre) => genre.name).toList();
  }

  /// Check if genre exists
  bool genreExists(String genreName) {
    return state.genres.any((genre) => 
      genre.name.toLowerCase() == genreName.toLowerCase()
    );
  }

  /// Notify that genres have been updated
  void notifyGenresUpdated() {
    state = state.copyWith(lastUpdated: DateTime.now());
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for GenreGlobalController
final genreProvider = StateNotifierProvider<GenreGlobalController, GenreState>((ref) {
  return GenreGlobalController(ref);
});

/// Auto-refresh provider for genres (refreshes every 5 minutes)
final autoRefreshGenreProvider = StreamProvider<GenreState>((ref) {
  return Stream.periodic(const Duration(minutes: 5), (count) {
    // Only refresh if we have initial data and no error
    final currentState = ref.read(genreProvider);
    if (currentState.error == null) {
      ref.read(genreProvider.notifier).refreshGenres();
    }
    return ref.read(genreProvider);
  });
});

/// Provider for easy access to genres list
final genresListProvider = Provider<List<GenreModel>>((ref) {
  return ref.watch(genreProvider).genres;
});

/// Provider for genre search functionality
final genreSearchProvider = Provider.family<List<GenreModel>, String>((ref, query) {
  final genreController = ref.watch(genreProvider.notifier);
  return genreController.searchGenres(query);
});

/// Provider for popular genres
final popularGenresProvider = Provider.family<List<GenreModel>, int>((ref, limit) {
  final genreController = ref.watch(genreProvider.notifier);
  return genreController.getPopularGenres(limit: limit);
});

/// Provider for genre names only
final genreNamesProvider = Provider<List<String>>((ref) {
  final genreController = ref.watch(genreProvider.notifier);
  return genreController.getGenreNames();
}); 