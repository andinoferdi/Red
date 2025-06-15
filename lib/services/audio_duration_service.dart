import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import '../models/song.dart';
import 'pocketbase_service.dart';

/// Service for detecting audio file duration and updating database
class AudioDurationService {
  static final AudioDurationService _instance = AudioDurationService._internal();
  final PocketBaseService _pbService = GetIt.I<PocketBaseService>();
  final AudioPlayer _durationPlayer = AudioPlayer();

  factory AudioDurationService() {
    return _instance;
  }

  AudioDurationService._internal();

  /// Get actual MP3 duration from audio file
  Future<Duration?> getAudioFileDuration(String audioUrl) async {
    try {
      // Create a separate audio player just for duration detection
      final durationPlayer = AudioPlayer();
      
      try {
        // Set audio source and wait for duration
        await durationPlayer.setUrl(audioUrl);
        
        // Wait for duration to be available
        Duration? duration = durationPlayer.duration;
        int attempts = 0;
        const maxAttempts = 10;
        
        while (duration == null && attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 200));
          duration = durationPlayer.duration;
          attempts++;
        }
        
        if (duration != null) {
          return duration;
        } else {
          debugPrint('⚠️ Could not detect duration after $maxAttempts attempts');
          return null;
        }
      } finally {
        // Always dispose the temporary player
        await durationPlayer.dispose();
      }
    } catch (e) {
      debugPrint('❌ Error getting audio duration: $e');
      return null;
    }
  }

  /// Update song duration in PocketBase database
  Future<bool> updateSongDurationInDatabase(String songId, int durationInSeconds) async {
    try {
      await _pbService.pb.collection('songs').update(songId, body: {
        'duration': durationInSeconds,
      });
      
      return true;
    } catch (e) {
      debugPrint('❌ Error updating song duration in database: $e');
      return false;
    }
  }

  /// Get song audio URL (same logic as PlayerController)
  String? _getSongAudioUrl(Song song) {
    try {
      String? url;
      
      // Try to use audio file name from model if available
      if (song.audioFileName != null && song.audioFileName!.isNotEmpty) {
        url = '${_pbService.pb.baseUrl}/api/files/songs/${song.id}/${song.audioFileName}';
      } else {
        // Use default file name if not available in model
        url = '${_pbService.pb.baseUrl}/api/files/songs/${song.id}/dream_on_no3ma56xq7.mp3';
      }
      
      return url;
    } catch (e) {
      debugPrint('Error getting song audio URL: $e');
      return null;
    }
  }

  /// Update single song duration by detecting from MP3 file
  Future<bool> updateSongDuration(Song song) async {
    try {
      // Skip if song already has duration
      if (song.durationInSeconds > 0) {
        return true;
      }
      
      // Get audio URL
      final audioUrl = _getSongAudioUrl(song);
      if (audioUrl == null) {
        debugPrint('❌ No audio URL available for song: ${song.title}');
        return false;
      }

      // Get actual duration from MP3 file
      final duration = await getAudioFileDuration(audioUrl);
      if (duration == null) {
        debugPrint('❌ Could not detect duration for song: ${song.title}');
        return false;
      }

      // Update database
      final success = await updateSongDurationInDatabase(song.id, duration.inSeconds);
      
      return success;
    } catch (e) {
      debugPrint('❌ Error updating song duration: $e');
      return false;
    }
  }

  /// Update all songs with missing duration (duration = 0)
  Future<void> updateAllSongsDuration() async {
    try {
      // Get all songs with duration = 0
      final response = await _pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 500, // Adjust based on your needs
        filter: 'duration = 0',
        expand: 'artist_id,album_id',
      );

      final List<Song> songsToUpdate = response.items
          .map((record) => Song.fromRecord(record))
          .toList();

      if (songsToUpdate.isEmpty) {
        return;
      }

      int successCount = 0;
      int failCount = 0;

      // Process each song
      for (int i = 0; i < songsToUpdate.length; i++) {
        final song = songsToUpdate[i];
        
        final success = await updateSongDuration(song);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
        
        // Add small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('📈 Duration update completed:');
      debugPrint('✅ Success: $successCount songs');
      debugPrint('❌ Failed: $failCount songs');
      debugPrint('📊 Total processed: ${songsToUpdate.length} songs');
      
    } catch (e) {
      debugPrint('❌ Error in bulk song duration update: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _durationPlayer.dispose();
  }
} 

