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
    
    // Start with neutral colors immediately to avoid any random colors
    const neutralColors = DominantColors(
      primary: Color(0xFF4A4A4A),
      secondary: Color(0xFF606060),
      backgroundStart: Color(0xFF2A2A2A),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFF707070),
    );
    
    // Set neutral colors immediately
    state = state.copyWith(
      colors: neutralColors,
      currentSongId: song.id,
      isLoading: false,
      hasError: false,
    );
    
    // Add a small delay to make transition smoother and less jarring
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Now extract actual album colors in background
    try {
      // Check if we have a valid image URL
      if (song.albumArtUrl.isEmpty || !_isValidImageUrl(song.albumArtUrl)) {
        // No album art, keep neutral colors
        return;
      }
      
      // Extract colors from album art URL
      final colors = await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
      
      // Update state with extracted colors only if this is still the current song
      if (state.currentSongId == song.id) {
        state = state.copyWith(
          colors: colors,
          isLoading: false,
          hasError: false,
        );
      }
    } catch (e) {
      // On error, keep the neutral colors we already set
      debugPrint('Color extraction failed for ${song.title}: $e');
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
    debugPrint('\n=== DEBUG COLOR EXTRACTION ===');
    debugPrint('Song: ${song.title}');
    debugPrint('Artist: ${song.artist}');
    debugPrint('Album Art URL: ${song.albumArtUrl}');
    
    // Clear cache first to ensure fresh extraction
    ColorExtractor.clearCache();
    
    final colors = await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
    
    debugPrint('Primary Color: ${colors.primary}');
    debugPrint('Secondary Color: ${colors.secondary}');
    debugPrint('Background Start: ${colors.backgroundStart}');
    debugPrint('Background End: ${colors.backgroundEnd}');
    debugPrint('Accent Color: ${colors.accent}');
    debugPrint('==============================\n');
    
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
  
  /// Initial state with default colors (neutral gray instead of purple)
  factory DynamicColorState.initial() {
    return const DynamicColorState(
      colors: DominantColors(
        primary: Color(0xFF4A4A4A),
        secondary: Color(0xFF606060),
        backgroundStart: Color(0xFF2A2A2A),
        backgroundEnd: Color(0xFF1A1A1A),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFB3B3B3),
        accent: Color(0xFF707070),
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

