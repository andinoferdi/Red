import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../widgets/shimmer_widget.dart';

/// Utility functions for handling images
class ImageHelpers {
  /// Private constructor to prevent instantiation
  ImageHelpers._();
  
  /// Generate a full avatar URL from a user record
  /// Returns null if no avatar is available
  static String? getAvatarUrl(RecordModel? user, String? baseUrl) {
    if (user == null) return null;
    if (baseUrl == null) return null;
    
    // Check if user has an avatar field with data
    final avatar = user.data['avatar'];
    if (avatar == null || avatar is! String || avatar.isEmpty) return null;
    
    // Check if it's already a full URL
    if (avatar.startsWith('http')) return avatar;
    
    // Format: {baseUrl}/api/files/{collectionId}/{recordId}/{fileName}
    return '$baseUrl/api/files/${user.collectionId}/${user.id}/$avatar';
  }

  /// Validate if a URL is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Check if it's a valid HTTP/HTTPS URL
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }
      
      // Check if it has a valid host
      if (!uri.hasAuthority || uri.host.isEmpty) {
        return false;
      }
      
      // Check if path looks like a file path
      if (uri.path.isEmpty || !uri.path.contains('/')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get a safe image URL, returns empty string if invalid
  static String getSafeImageUrl(String? url) {
    return isValidImageUrl(url) ? url! : '';
  }
  
  /// Build a safe network image widget with robust error handling
  static Widget buildSafeNetworkImage({
    required String? imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? fallbackWidget,
    BorderRadius? borderRadius,
    bool showLoadingIndicator = false,
  }) {
    final fallback = fallbackWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[800],
      child: Icon(
        Icons.music_note,
        color: Colors.white,
        size: width * 0.4,
      ),
    );
    
    // CRITICAL: Multiple layers of validation to prevent 404 errors
    if (!isValidImageUrl(imageUrl)) {
      return borderRadius != null 
          ? ClipRRect(borderRadius: borderRadius, child: fallback)
          : fallback;
    }
    
    // ADDITIONAL: Check for incomplete URLs (ending with slash)
    final cleanUrl = imageUrl!.trim();
    if (cleanUrl.endsWith('/') || cleanUrl.split('/').last.isEmpty) {
      return borderRadius != null 
          ? ClipRRect(borderRadius: borderRadius, child: fallback)
          : fallback;
    }
    
    // ADDITIONAL: Check for old collection IDs that are known to cause issues
    if (cleanUrl.contains('pbc_2683869272')) {
      return borderRadius != null 
          ? ClipRRect(borderRadius: borderRadius, child: fallback)
          : fallback;
    }
    
    final imageWidget = Image.network(
      cleanUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallback;
      },
      loadingBuilder: showLoadingIndicator ? (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Add fade-in animation when image is loaded
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: child,
          );
        }
        
        // Use shimmer effect for smooth loading
        return ShimmerImagePlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      } : null,
    );
    
    return borderRadius != null 
        ? ClipRRect(borderRadius: borderRadius, child: imageWidget)
        : imageWidget;
  }
}

/// Extension methods for RecordModel
extension RecordModelExtensions on RecordModel {
  /// Get the avatar URL for this user record
  /// Returns null if no avatar is available or baseUrl is null
  String? getAvatarUrl(String? baseUrl) {
    return ImageHelpers.getAvatarUrl(this, baseUrl);
  }
  
  /// Get the user's name from the record
  /// Returns a default value if not found
  String getName([String defaultValue = 'User']) {
    return data['name']?.toString() ?? defaultValue;
  }
  
  /// Get the user's email from the record
  /// Returns a default value if not found
  String getEmail([String defaultValue = '']) {
    return data['email']?.toString() ?? defaultValue;
  }
}
