import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  static final Map<String, DominantColors> _colorCache = {};
  
  // Spotify-like elegant color palettes based on dominant colors
  static const Map<String, DominantColors> _elegantPalettes = {
    'purple': DominantColors(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFFA855F7),
      backgroundStart: Color(0xFF2D1B69),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFF9333EA),
    ),
    'blue': DominantColors(
      primary: Color(0xFF3B82F6),
      secondary: Color(0xFF1D4ED8),
      backgroundStart: Color(0xFF1E3A8A),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFF2563EB),
    ),
    'green': DominantColors(
      primary: Color(0xFF22C55E),
      secondary: Color(0xFF16A34A),
      backgroundStart: Color(0xFF166534),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFF15803D),
    ),
    'red': DominantColors(
      primary: Color(0xFFEF4444),
      secondary: Color(0xFFDC2626),
      backgroundStart: Color(0xFF991B1B),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFFB91C1C),
    ),
    'orange': DominantColors(
      primary: Color(0xFFF97316),
      secondary: Color(0xFFEA580C),
      backgroundStart: Color(0xFF9A3412),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFFCC5500),
    ),
    'pink': DominantColors(
      primary: Color(0xFFEC4899),
      secondary: Color(0xFFDB2777),
      backgroundStart: Color(0xFF9D174D),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFFBE185D),
    ),
    'monochrome': DominantColors(
      primary: Color(0xFF4A4A4A),
      secondary: Color(0xFF606060),
      backgroundStart: Color(0xFF2A2A2A),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFF707070),
    ),
  };
  
  /// Extract dominant colors from image URL with smart color selection
  static Future<DominantColors> extractColorsFromUrl(String imageUrl) async {
    // Check cache first
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl]!;
    }
    
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return getDefaultColors();
      }
      
      // Create image from bytes
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Generate palette with more colors for better analysis
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 32, // Increased for better color analysis
      );
      
      // Extract colors using smart algorithm
      final dominantColors = _extractSmartColors(paletteGenerator);
      
      // Cache the result
      _colorCache[imageUrl] = dominantColors;
      
      return dominantColors;
    } catch (e) {
      debugPrint('Error extracting colors from image: $e');
      return getDefaultColors();
    }
  }
  
  /// Smart color extraction algorithm inspired by Spotify
  static DominantColors _extractSmartColors(PaletteGenerator palette) {
    // Get all available colors and their populations
    final allColors = <Color, int>{};
    
    // Collect all colors with their populations
    if (palette.dominantColor != null) {
      allColors[palette.dominantColor!.color] = palette.dominantColor!.population;
    }
    if (palette.vibrantColor != null) {
      allColors[palette.vibrantColor!.color] = palette.vibrantColor!.population;
    }
    if (palette.darkVibrantColor != null) {
      allColors[palette.darkVibrantColor!.color] = palette.darkVibrantColor!.population;
    }
    if (palette.lightVibrantColor != null) {
      allColors[palette.lightVibrantColor!.color] = palette.lightVibrantColor!.population;
    }
    if (palette.mutedColor != null) {
      allColors[palette.mutedColor!.color] = palette.mutedColor!.population;
    }
    if (palette.darkMutedColor != null) {
      allColors[palette.darkMutedColor!.color] = palette.darkMutedColor!.population;
    }
    if (palette.lightMutedColor != null) {
      allColors[palette.lightMutedColor!.color] = palette.lightMutedColor!.population;
    }
    
    // Filter out bad colors and select the best primary color
    final bestColor = _selectBestPrimaryColor(allColors);
    
    // Find the closest elegant palette or create custom one
    final elegantPalette = _findOrCreateElegantPalette(bestColor);
    
    return elegantPalette;
  }
  
  /// Select the best primary color from available colors
  static Color _selectBestPrimaryColor(Map<Color, int> colors) {
    if (colors.isEmpty) {
      return const Color(0xFF8B5CF6); // Default purple
    }
    
    // Special logic: Check if this is a monochrome album (black/white/gray dominant)
    if (_isMonochromeAlbum(colors)) {
      print('🎨 DETECTED: Monochrome album - using gray palette');
      return const Color(0xFF4A4A4A); // Return medium gray for monochrome albums
    }
    
    // Special logic: Check if this is a sky/cloud album
    if (_isSkyCloudAlbum(colors)) {
      print('🎨 DETECTED: Sky/Cloud album - using muted dominant color');
      return _selectMutedDominantColor(colors);
    }
    
    // Special logic: Check if there's a strong purple presence in the image
    Color? strongPurple = _findStrongPurple(colors);
    if (strongPurple != null) {
      print('🎨 DETECTED: Strong purple presence');
      return strongPurple;
    }
    
    // Score each color based on multiple criteria
    Color bestColor = colors.keys.first;
    double bestScore = 0;
    
    for (final entry in colors.entries) {
      final color = entry.key;
      final population = entry.value;
      
      // Skip colors that are too close to black, white, or gray
      if (_isColorUndesirable(color)) {
        continue;
      }
      
      // Calculate score based on:
      // 1. Saturation (more saturated = better)
      // 2. Population (more common = better)
      // 3. Vibrance (avoid dull colors)
      // 4. Darkness/Lightness balance
      
      final hsl = HSLColor.fromColor(color);
      final score = _calculateColorScore(hsl, population, colors.values.reduce(math.max));
      
      if (score > bestScore) {
        bestScore = score;
        bestColor = color;
      }
    }
    
    print('🎨 SELECTED: Best color with score $bestScore');
    return bestColor;
  }
  
  /// Select muted version of dominant color for sky/cloud albums
  static Color _selectMutedDominantColor(Map<Color, int> colors) {
    // Find the most dominant color
    Color dominantColor = colors.keys.first;
    int maxPopulation = 0;
    
    for (final entry in colors.entries) {
      if (entry.value > maxPopulation) {
        maxPopulation = entry.value;
        dominantColor = entry.key;
      }
    }
    
    // Convert to HSL and create a muted, elegant version
    final hsl = HSLColor.fromColor(dominantColor);
    
    // Reduce saturation for elegance but keep some color
    double newSaturation = math.max(0.3, hsl.saturation * 0.6);
    
    // Adjust lightness for better contrast
    double newLightness = hsl.lightness;
    if (newLightness > 0.7) {
      newLightness = 0.4; // Darken very light colors
    } else if (newLightness < 0.3) {
      newLightness = 0.4; // Lighten very dark colors
    }
    
    return hsl.withSaturation(newSaturation).withLightness(newLightness).toColor();
  }
  
  /// Detect if album art is primarily monochrome (black/white/gray)
  static bool _isMonochromeAlbum(Map<Color, int> colors) {
    int totalPopulation = colors.values.fold(0, (sum, pop) => sum + pop);
    int monochromePopulation = 0;
    
    for (final entry in colors.entries) {
      final color = entry.key;
      final hsl = HSLColor.fromColor(color);
      
      // Count colors with very low saturation (gray, black, white)
      if (hsl.saturation < 0.15) {
        monochromePopulation += entry.value;
      }
    }
    
    // Only treat as monochrome if >75% is truly grayscale (very strict)
    double monochromeRatio = monochromePopulation / totalPopulation;
    return monochromeRatio > 0.75;
  }
  
  /// Detect if album art has sky/cloud theme (should use muted colors)
  static bool _isSkyCloudAlbum(Map<Color, int> colors) {
    int totalPopulation = colors.values.fold(0, (sum, pop) => sum + pop);
    int skyCloudPopulation = 0;
    
    for (final entry in colors.entries) {
      final color = entry.key;
      final hsl = HSLColor.fromColor(color);
      
      // Count light blues, whites, and very light colors (sky/cloud characteristics)
      bool isLightBlue = hsl.hue >= 180 && hsl.hue <= 240 && 
                        hsl.saturation > 0.2 && hsl.saturation < 0.7 && 
                        hsl.lightness > 0.5;
      bool isCloudWhite = hsl.lightness > 0.8 && hsl.saturation < 0.3;
      
      if (isLightBlue || isCloudWhite) {
        skyCloudPopulation += entry.value;
      }
    }
    
    // If >50% is sky/cloud colors, treat specially
    double skyCloudRatio = skyCloudPopulation / totalPopulation;
    return skyCloudRatio > 0.5;
  }
  
  /// Find strong purple colors in the palette for special handling
  static Color? _findStrongPurple(Map<Color, int> colors) {
    Color? bestPurple;
    double bestPurpleScore = 0;
    
    for (final entry in colors.entries) {
      final color = entry.key;
      final population = entry.value;
      final hsl = HSLColor.fromColor(color);
      
      // Check if this is a purple color (240-320 degrees)
      if (hsl.hue >= 240 && hsl.hue <= 320) {
        // Must have good saturation and lightness
        if (hsl.saturation > 0.3 && hsl.lightness > 0.2 && hsl.lightness < 0.8) {
          // Calculate purple-specific score
          double purpleScore = (population / colors.values.reduce(math.max)) * 
                              hsl.saturation * 
                              (1.0 - (hsl.lightness - 0.5).abs() * 2);
          
          if (purpleScore > bestPurpleScore) {
            bestPurpleScore = purpleScore;
            bestPurple = color;
          }
        }
      }
    }
    
    // Only return purple if it has a decent presence (threshold lowered for better purple detection)
    if (bestPurpleScore > 0.15) { // Lowered from potential higher threshold
      return bestPurple;
    }
    
    return null;
  }
  
  /// Check if a color is undesirable (too dull, too extreme, etc.)
  static bool _isColorUndesirable(Color color) {
    final hsl = HSLColor.fromColor(color);
    
    // Skip colors that are too close to grayscale
    if (hsl.saturation < 0.15) return true;
    
    // Skip colors that are too dark or too light
    if (hsl.lightness < 0.1 || hsl.lightness > 0.9) return true;
    
    // Skip muddy/brownish colors (specific hue ranges that look bad)
    final hue = hsl.hue;
    
    // Avoid muddy browns (30-60 degrees with low saturation)
    if (hue >= 30 && hue <= 60 && hsl.saturation < 0.4) return true;
    
    // Avoid sickly yellows and greens
    if (hue >= 45 && hue <= 75 && hsl.lightness > 0.7) return true;
    
    // Avoid dull oranges - TIGHTENED criteria
    if (hue >= 20 && hue <= 40 && hsl.saturation < 0.6) return true;
    
    // NEW: Avoid most orange colors unless they're very vibrant
    if (hue >= 15 && hue <= 45) {
      // Only allow very vibrant oranges with specific characteristics
      if (hsl.saturation < 0.8 || hsl.lightness < 0.4 || hsl.lightness > 0.7) {
        return true;
      }
    }
    
    // NEW: Avoid yellow-oranges completely
    if (hue >= 40 && hue <= 60) return true;
    
    return false;
  }
  
  /// Calculate a score for a color based on multiple criteria
  static double _calculateColorScore(HSLColor hsl, int population, int maxPopulation) {
    // Base score from population (0-1)
    double populationScore = population / maxPopulation;
    
    // Saturation score (prefer saturated colors)
    double saturationScore = hsl.saturation;
    
    // Lightness score (prefer colors in middle range)
    double lightnessScore = 1.0 - (hsl.lightness - 0.5).abs() * 2;
    
    // Hue preference (some hues are more pleasing) - INCREASED weight
    double hueScore = _getHuePreferenceScore(hsl.hue);
    
    // Combine scores with NEW weights (hue preference increased significantly)
    return populationScore * 0.2 + 
           saturationScore * 0.3 + 
           lightnessScore * 0.1 + 
           hueScore * 0.4; // Increased from 0.1 to 0.4 for stronger purple preference
  }
  
  /// Get preference score for different hues
  static double _getHuePreferenceScore(double hue) {
    // Purple/Blue range (240-280) - HIGHEST preference (increased from 1.0 to 1.5)
    if (hue >= 240 && hue <= 280) return 1.5;
    
    // Extended purple range (280-320) - High preference for pink-purples
    if (hue >= 280 && hue <= 320) return 1.3;
    
    // Blue range (200-240) 
    if (hue >= 200 && hue <= 240) return 1.2;
    
    // Pink/Red range (320-360 and 0-20) - but lower than purple
    if ((hue >= 320 && hue <= 360) || (hue >= 0 && hue <= 20)) return 0.8;
    
    // Green range (80-160)
    if (hue >= 80 && hue <= 160) return 0.6;
    
    // Orange range (20-45) - SIGNIFICANTLY reduced
    if (hue >= 20 && hue <= 45) return 0.3;
    
    // Yellow/yellow-green range (45-80) - LOWEST preference
    if (hue >= 45 && hue <= 80) return 0.1;
    
    return 0.4; // Default (reduced from 0.5)
  }
  
  /// Find the closest elegant palette or create a custom one
  static DominantColors _findOrCreateElegantPalette(Color primaryColor) {
    final hsl = HSLColor.fromColor(primaryColor);
    final hue = hsl.hue;
    
    // Check if this is a monochrome color (very low saturation)
    if (hsl.saturation < 0.15) {
      return _elegantPalettes['monochrome']!;
    }
    
    // Map hue ranges to elegant palettes
    if (hue >= 240 && hue <= 280) {
      // Purple range
      return _elegantPalettes['purple']!._withPrimaryColor(primaryColor);
    } else if (hue >= 200 && hue <= 240) {
      // Blue range
      return _elegantPalettes['blue']!._withPrimaryColor(primaryColor);
    } else if (hue >= 80 && hue <= 160) {
      // Green range
      return _elegantPalettes['green']!._withPrimaryColor(primaryColor);
    } else if ((hue >= 300 && hue <= 360) || (hue >= 0 && hue <= 20)) {
      // Red/Pink range
      if (hue >= 320 || hue <= 10) {
        return _elegantPalettes['pink']!._withPrimaryColor(primaryColor);
      } else {
        return _elegantPalettes['red']!._withPrimaryColor(primaryColor);
      }
    } else if (hue >= 20 && hue <= 45) {
      // Orange range
      return _elegantPalettes['orange']!._withPrimaryColor(primaryColor);
    } else {
      // Default to purple for edge cases
      return _elegantPalettes['purple']!._withPrimaryColor(primaryColor);
    }
  }
  
  /// Get contrasting text color (white or black) based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    
    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  
  /// Get default colors when extraction fails
  static DominantColors getDefaultColors() {
    return _elegantPalettes['purple']!;
  }
  
  /// Clear color cache
  static void clearCache() {
    _colorCache.clear();
  }
  
  /// Clear specific color from cache
  static void clearColorFromCache(String imageUrl) {
    _colorCache.remove(imageUrl);
  }
  
  /// Get elegant palette by key (for debugging and testing)
  static DominantColors? getElegantPalette(String key) {
    return _elegantPalettes[key];
  }
  
  /// Get all available elegant palette keys
  static List<String> getElegantPaletteKeys() {
    return _elegantPalettes.keys.toList();
  }
  
  /// Test color extraction with debug output
  static Future<DominantColors> testColorExtraction(String imageUrl, {bool verbose = false}) async {
    if (verbose) {
      debugPrint('🎨 Testing color extraction for: $imageUrl');
    }
    
    try {
      final colors = await extractColorsFromUrl(imageUrl);
      
      if (verbose) {
        debugPrint('✅ Extracted colors:');
        debugPrint('   Primary: ${colors.primary.toString()}');
        debugPrint('   Secondary: ${colors.secondary.toString()}');
        debugPrint('   Background: ${colors.backgroundStart.toString()} → ${colors.backgroundEnd.toString()}');
        debugPrint('   Accent: ${colors.accent.toString()}');
      }
      
      return colors;
    } catch (e) {
      if (verbose) {
        debugPrint('❌ Color extraction failed: $e');
      }
      return getDefaultColors();
    }
  }
  
  /// Generate consistent colors based on song name hash (fallback method)
  static DominantColors _generateConsistentColors(String songName) {
    final hash = songName.hashCode.abs();
    final paletteKeys = _elegantPalettes.keys.toList();
    
    // Exclude monochrome from random selection (only for explicit detection)
    final availablePalettes = paletteKeys.where((key) => key != 'monochrome').toList();
    final selectedPalette = availablePalettes[hash % availablePalettes.length];
    
    return _elegantPalettes[selectedPalette]!;
  }
}

/// Data class to hold extracted dominant colors
class DominantColors {
  final Color primary;
  final Color secondary;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  
  const DominantColors({
    required this.primary,
    required this.secondary,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });
  
  /// Create a new palette with adjusted primary color while keeping harmony
  DominantColors _withPrimaryColor(Color newPrimary) {
    final hsl = HSLColor.fromColor(newPrimary);
    
    // Adjust the primary color to be more suitable
    final adjustedPrimary = hsl.withSaturation(
      math.max(0.6, hsl.saturation)
    ).withLightness(
      math.max(0.4, math.min(0.7, hsl.lightness))
    ).toColor();
    
    // Create harmonious secondary color
    final secondaryHsl = hsl.withHue((hsl.hue + 20) % 360);
    final secondary = secondaryHsl.toColor();
    
    // Create darker background variants
    final backgroundStart = hsl.withLightness(0.15).withSaturation(0.8).toColor();
    const backgroundEnd = Color(0xFF1A1A1A);
    
    // Create accent color (lighter, more vibrant)
    final accent = hsl.withLightness(
      math.min(0.8, hsl.lightness + 0.2)
    ).withSaturation(
      math.min(1.0, hsl.saturation + 0.1)
    ).toColor();
    
    return DominantColors(
      primary: adjustedPrimary,
      secondary: secondary,
      backgroundStart: backgroundStart,
      backgroundEnd: backgroundEnd,
      textPrimary: Colors.white,
      textSecondary: const Color(0xFFB3B3B3),
      accent: accent,
    );
  }
  
  /// Create gradient for backgrounds
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );
  
  /// Create gradient for cards/containers
  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary.withValues(alpha: 0.8),
      secondary.withValues(alpha: 0.6),
      primary.withValues(alpha: 0.4),
    ],
  );
  
  /// Create gradient for lyrics container
  LinearGradient get lyricsGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, primary.withValues(alpha: 0.8)],
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DominantColors &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          secondary == other.secondary &&
          backgroundStart == other.backgroundStart &&
          backgroundEnd == other.backgroundEnd &&
          textPrimary == other.textPrimary &&
          textSecondary == other.textSecondary &&
          accent == other.accent;

  @override
  int get hashCode =>
      primary.hashCode ^
      secondary.hashCode ^
      backgroundStart.hashCode ^
      backgroundEnd.hashCode ^
      textPrimary.hashCode ^
      textSecondary.hashCode ^
      accent.hashCode;
} 