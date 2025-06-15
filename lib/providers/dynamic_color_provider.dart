import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/color_extractor.dart';
import '../models/song.dart';
import '../controllers/player_controller.dart';

/// Provider for managing dynamic colors based on current song's album art
final dynamicColorProvider = StateNotifierProvider<DynamicColorNotifier, DynamicColorState>((ref) {
  return DynamicColorNotifier(ref);
});

class DynamicColorNotifier extends StateNotifier<DynamicColorState> {
  final Ref _ref;
  
  DynamicColorNotifier(this._ref) : super(DynamicColorState.initial());
  
  /// Extract colors from song's album art with smart caching and fallbacks
  Future<void> extractColorsFromSong(Song song) async {
    // Don't extract if same song and colors already extracted
    if (state.currentSongId == song.id && state.colors != null && !state.isLoading) {
      return;
    }
    
    // Set loading state only if no colors are currently available
    if (state.colors == null) {
      state = state.copyWith(
        isLoading: true,
        currentSongId: song.id,
      );
    } else {
      // Keep current colors while loading new ones for smoother transitions
      state = state.copyWith(
        currentSongId: song.id,
        isLoading: false, // Don't show loading if we have colors
      );
    }
    
    try {
      // Check if we have a valid image URL
      if (song.albumArtUrl.isEmpty || !_isValidImageUrl(song.albumArtUrl)) {
        // Use intelligent fallback based on song/artist info
        final fallbackColors = _getIntelligentFallback(song);
        state = state.copyWith(
          colors: fallbackColors,
          isLoading: false,
          hasError: false,
        );
        return;
      }
      
      // Extract colors from album art URL
      final colors = await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
      
      // Update state with extracted colors
      state = state.copyWith(
        colors: colors,
        isLoading: false,
        hasError: false,
      );
    } catch (e) {
      // Use intelligent fallback instead of just default colors
      final fallbackColors = _getIntelligentFallback(song);
      
      state = state.copyWith(
        colors: fallbackColors,
        isLoading: false,
        hasError: true,
      );
    }
  }
  
  /// Check if image URL is valid
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// Get intelligent fallback colors based on song information
  DominantColors _getIntelligentFallback(Song song) {
    // Simple hash-based color selection for consistency
    final songHash = (song.title + song.artist).hashCode;
    final colorIndex = songHash.abs() % 6;
    
    // Map to elegant color palettes
    const colorKeys = ['purple', 'blue', 'green', 'red', 'orange', 'pink'];
    final selectedKey = colorKeys[colorIndex];
    
    // Get the elegant palette (this is a simplified access - in real implementation,
    // we'd need to expose the palettes from ColorExtractor)
    switch (selectedKey) {
      case 'blue':
        return const DominantColors(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF1D4ED8),
          backgroundStart: Color(0xFF1E3A8A),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFF2563EB),
        );
      case 'green':
        return const DominantColors(
          primary: Color(0xFF22C55E),
          secondary: Color(0xFF16A34A),
          backgroundStart: Color(0xFF166534),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFF15803D),
        );
      case 'red':
        return const DominantColors(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFFDC2626),
          backgroundStart: Color(0xFF991B1B),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFFB91C1C),
        );
      case 'orange':
        return const DominantColors(
          primary: Color(0xFFF97316),
          secondary: Color(0xFFEA580C),
          backgroundStart: Color(0xFF9A3412),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFFCC5500),
        );
      case 'pink':
        return const DominantColors(
          primary: Color(0xFFEC4899),
          secondary: Color(0xFFDB2777),
          backgroundStart: Color(0xFF9D174D),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFFBE185D),
        );
      default: // purple
        return const DominantColors(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFA855F7),
          backgroundStart: Color(0xFF2D1B69),
          backgroundEnd: Color(0xFF1A1A1A),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFB3B3B3),
          accent: Color(0xFF9333EA),
        );
    }
  }
  
  /// Preload colors for multiple songs (for better UX in playlists)
  Future<void> preloadColorsForSongs(List<Song> songs) async {
    for (final song in songs.take(5)) { // Limit to 5 songs to avoid excessive loading
      if (song.albumArtUrl.isNotEmpty && _isValidImageUrl(song.albumArtUrl)) {
        try {
          // This will cache the colors without updating the state
          await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
        } catch (e) {
          // Ignore errors during preloading
        }
      }
    }
  }
  
  /// Reset to default colors
  void resetToDefault() {
    state = DynamicColorState.initial();
  }
  
  /// Clear colors for specific song
  void clearColorsForSong(String songId) {
    if (state.currentSongId == songId) {
      state = DynamicColorState.initial();
    }
    
    // Also clear from cache
    ColorExtractor.clearColorFromCache(songId);
  }
  
  /// Force refresh colors for current song
  Future<void> forceRefresh() async {
    if (state.currentSongId != null) {
      // Clear cache first
      ColorExtractor.clearCache();
      
      // Clear current state
      state = state.copyWith(colors: null, isLoading: true);
    }
  }
  
  /// Force refresh for specific song ID
  Future<void> forceRefreshForSong(String songId) async {
    // Clear cache
    ColorExtractor.clearCache();
    
    // If this is the current song, refresh it
    if (state.currentSongId == songId) {
      state = state.copyWith(colors: null, isLoading: true);
    }
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    ColorExtractor.clearCache();
  }
  
  /// Force refresh colors for current song
  Future<void> forceRefreshCurrentSong() async {
    final currentSong = _ref.read(playerControllerProvider).currentSong;
    if (currentSong != null) {
      await extractColorsFromSong(currentSong);
    }
  }
  
  /// Extract colors with debug information
  Future<DominantColors> extractColorsWithDebug(Song song) async {
    print('\n=== DEBUG COLOR EXTRACTION ===');
    print('Song: ${song.title}');
    print('Artist: ${song.artist}');
    print('Album Art URL: ${song.albumArtUrl}');
    
    // Clear cache first to ensure fresh extraction
    ColorExtractor.clearCache();
    
    final colors = await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
    
    print('Primary Color: ${colors.primary}');
    print('Secondary Color: ${colors.secondary}');
    print('Background Start: ${colors.backgroundStart}');
    print('Background End: ${colors.backgroundEnd}');
    print('Accent Color: ${colors.accent}');
    print('==============================\n');
    
    return colors;
  }
}

/// State class for dynamic colors
class DynamicColorState {
  final DominantColors? colors;
  final bool isLoading;
  final bool hasError;
  final String? currentSongId;
  
  const DynamicColorState({
    this.colors,
    this.isLoading = false,
    this.hasError = false,
    this.currentSongId,
  });
  
  /// Initial state with default colors
  factory DynamicColorState.initial() {
    return const DynamicColorState(
      colors: DominantColors(
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFFA855F7),
        backgroundStart: Color(0xFF2D1B69),
        backgroundEnd: Color(0xFF1A1A1A),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFB3B3B3),
        accent: Color(0xFF9333EA),
      ),
      isLoading: false,
      hasError: false,
      currentSongId: null,
    );
  }
  
  /// Copy with method for state updates
  DynamicColorState copyWith({
    DominantColors? colors,
    bool? isLoading,
    bool? hasError,
    String? currentSongId,
  }) {
    return DynamicColorState(
      colors: colors ?? this.colors,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      currentSongId: currentSongId ?? this.currentSongId,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicColorState &&
          runtimeType == other.runtimeType &&
          colors == other.colors &&
          isLoading == other.isLoading &&
          hasError == other.hasError &&
          currentSongId == other.currentSongId;

  @override
  int get hashCode =>
      colors.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      currentSongId.hashCode;
} 