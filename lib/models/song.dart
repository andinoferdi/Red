import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/pocketbase_service.dart';

part 'song.g.dart';
part 'song.freezed.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String albumArtUrl,
    required int durationInSeconds,
    required String albumName,
    String? lyrics,
    String? playlistId,
    String? audioFileUrl,
    String? audioFileName,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  
  /// Create a Song from a PocketBase record
  static Song fromRecord(RecordModel record) {
    // Get expanded artist and album if available
    final artistRecord = record.expand['artist_id']?[0];
    final albumRecord = record.expand['album_id']?[0];
    
    // Extract artist name
    final artistName = artistRecord?.data['name'] as String? ?? 'Unknown Artist';
    
    // Extract album name - try 'title' first, then 'name'
    String albumName = 'Unknown Album';
    if (albumRecord != null) {
      albumName = albumRecord.data['title'] as String? ?? 
                  albumRecord.data['name'] as String? ?? 
                  'Unknown Album';
    }
    
    // Extract album cover URL with enhanced error handling
    String albumArtUrl = '';
    if (albumRecord != null && albumRecord.data['cover_image'] != null) {
      try {
        final coverImage = albumRecord.data['cover_image'];
        
        
        if (coverImage is String && coverImage.trim().isNotEmpty) {
          // CRITICAL: Validate filename format before generating URL
          final trimmedImage = coverImage.trim();
          
          // Check if it's a valid filename (must contain extension)
          if (!trimmedImage.contains('.') || trimmedImage.startsWith('.') || 
              trimmedImage.endsWith('.') || trimmedImage.length < 3) {

            albumArtUrl = '';
          } else {
            // Generate proper PocketBase file URL using service
            final pbService = PocketBaseService();
            final baseUrl = pbService.pb.baseUrl;
            final collectionId = albumRecord.collectionId;
            final recordId = albumRecord.id;
            
            // Validate that all components are not empty and not just whitespace
            if (baseUrl.trim().isNotEmpty && 
                collectionId.trim().isNotEmpty && 
                recordId.trim().isNotEmpty) {
              
              albumArtUrl = '$baseUrl/api/files/$collectionId/$recordId/$trimmedImage';

              
              // ENHANCED: Validate the generated URL immediately
              if (!_isValidPocketBaseUrl(albumArtUrl)) {

                albumArtUrl = '';
              }
            } else {

              albumArtUrl = '';
            }
          }
        } else {

          albumArtUrl = '';
        }
      } catch (e) {
        // Enhanced error handling with fallback

        albumArtUrl = '';
      }
    } else {

    }
    
    final lyrics = record.data['lyrics'] as String?;
    
    // Get audio file information
    String? audioFileName;
    
    // Nama field audio di PocketBase
    const String audioField = 'audio_file';
    
    // Cek apakah field audio_file ada dan berisi nilai
    if (record.data.containsKey(audioField) && record.data[audioField] != null) {
      final audioFileValue = record.data[audioField];
      
      // PocketBase menyimpan nama file di field, ambil nama file jika bisa
      if (audioFileValue is String && audioFileValue.isNotEmpty) {
        audioFileName = audioFileValue;
      }
    }
    
    return Song(
      id: record.id,
      title: record.data['title'] as String? ?? 'Unknown Title',
      artist: artistName,
      albumArtUrl: albumArtUrl,
      durationInSeconds: record.data['duration'] as int? ?? 0,
      albumName: albumName,
      lyrics: lyrics,
      playlistId: record.data['playlist_id'] as String?,
      audioFileName: audioFileName,
      audioFileUrl: null, // URL akan dibuat di PlayerController
    );
  }
  
  /// Validate if a PocketBase URL is likely to be valid
  static bool _isValidPocketBaseUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      // Basic validation - should have proper structure
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4 || 
          pathSegments[0] != 'api' || 
          pathSegments[1] != 'files') {
        return false;
      }
      
      // Check that the last segment (filename) is not empty
      final filename = pathSegments.last;
      if (filename.isEmpty || !filename.contains('.')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Extension to convert duration in seconds to Duration
extension DurationExt on Song {
  Duration get duration => Duration(seconds: durationInSeconds);
}


