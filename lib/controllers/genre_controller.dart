import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/genre_repository.dart';
import '../models/genre_model.dart';
import '../services/pocketbase_service.dart';

/// Genre state management
class GenreState {
  final List<GenreModel> genres;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const GenreState({
    this.genres = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  /// Create a copy of this state
  GenreState copyWith({
    List<GenreModel>? genres,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return GenreState(
      genres: genres ?? this.genres,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  /// Initial state
  factory GenreState.initial() => const GenreState();
}

/// Genre controller
class GenreController extends StateNotifier<GenreState> {
  final GenreRepository _genreRepository;

  GenreController(this._genreRepository) : super(GenreState.initial());

  /// Load all genres
  Future<void> loadGenres() async {
    // Skip loading if already loaded and no errors
    if (state.genres.isNotEmpty && state.error == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genres = await _genreRepository.getGenres();
      
      state = state.copyWith(
        genres: genres,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh genres (force reload)
  Future<void> refreshGenres() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final genres = await _genreRepository.getGenres();
      
      state = state.copyWith(
        genres: genres,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for genre repository
final genreRepositoryProvider = Provider<GenreRepository>((ref) {
  final pbService = PocketBaseService();
  return GenreRepository(pbService);
});

/// Provider for genre controller
final genreControllerProvider = StateNotifierProvider<GenreController, GenreState>((ref) {
  final repository = ref.watch(genreRepositoryProvider);
  return GenreController(repository);
});
