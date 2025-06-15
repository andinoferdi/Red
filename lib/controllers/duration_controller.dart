import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/pocketbase_service.dart';

/// Provider for duration controller
final durationControllerProvider = StateNotifierProvider<DurationController, DurationState>(
  (ref) => DurationController(),
);

/// Controller for managing audio durations
class DurationController extends StateNotifier<DurationState> {
  static const int _batchSize = 10; // Process songs in smaller batches
  static const Duration _timeout = Duration(seconds: 15); // Timeout per song

  DurationController() : super(const DurationState.idle());

  /// Update durations for songs with missing duration data
  Future<void> updateMissingSongDurations() async {
    if (state is DurationLoading) return; // Prevent multiple simultaneous updates
    
    state = const DurationState.loading();
    
    try {
      final pbService = PocketBaseService();
      
      // Get songs with missing duration (duration = 0 or null)
      final response = await pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 500,
        filter: 'duration = 0 || duration = null',
      );
      
      if (response.items.isEmpty) {
        state = const DurationState.completed(
          successCount: 0,
          failCount: 0,
          message: 'No songs need duration updates',
        );
        return;
      }
      
      final songsToUpdate = response.items.map((record) => Song.fromRecord(record)).toList();
      await _updateSongDurationsInBatches(songsToUpdate);
      
    } catch (e) {
      state = DurationState.error('Failed to fetch songs: $e');
    }
  }

  /// Update durations for all songs (force update)
  Future<void> updateAllSongDurations() async {
    if (state is DurationLoading) return; // Prevent multiple simultaneous updates
    
    state = const DurationState.loading();
    
    try {
      final pbService = PocketBaseService();
      
      // Get all songs
      final response = await pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 500,
        sort: 'created',
      );
      
      if (response.items.isEmpty) {
        state = const DurationState.completed(
          successCount: 0,
          failCount: 0,
          message: 'No songs found',
        );
        return;
      }
      
      final songsToUpdate = response.items.map((record) => Song.fromRecord(record)).toList();
      await _updateSongDurationsInBatches(songsToUpdate);
      
    } catch (e) {
      state = DurationState.error('Failed to fetch all songs: $e');
    }
  }

  /// Alias for backward compatibility
  Future<void> updateAllSongsDuration() async {
    await updateAllSongDurations();
  }

  /// Process songs in batches to avoid memory issues
  Future<void> _updateSongDurationsInBatches(List<Song> songs) async {
    int successCount = 0;
    int failCount = 0;
    
    try {
      // Process songs in batches
      for (int i = 0; i < songs.length; i += _batchSize) {
        final batch = songs.skip(i).take(_batchSize).toList();
        
        // Update progress
        state = DurationState.progress(
          current: i,
          total: songs.length,
          currentSongTitle: batch.first.title,
        );
        
        // Process batch
        final results = await _processSongBatch(batch);
        successCount += results['success'] as int;
        failCount += results['fail'] as int;
        
        // Small delay between batches to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      state = DurationState.completed(
        successCount: successCount,
        failCount: failCount,
        message: 'Duration update completed',
      );
      
    } catch (e) {
      debugPrint('Error in bulk song duration update: $e');
      state = DurationState.error('Bulk update failed: $e');
    }
  }

  /// Process a batch of songs concurrently
  Future<Map<String, int>> _processSongBatch(List<Song> songs) async {
    int successCount = 0;
    int failCount = 0;
    
    // Process songs in the batch concurrently with limited concurrency
    final futures = songs.map((song) => _updateSingleSongDuration(song));
    final results = await Future.wait(futures, eagerError: false);
    
    for (final success in results) {
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }
    
    return {'success': successCount, 'fail': failCount};
  }

  /// Update duration for a single song
  Future<bool> _updateSingleSongDuration(Song song) async {
    AudioPlayer? audioPlayer;
    
    try {
      // Create audio player instance
      audioPlayer = AudioPlayer();
      
      // Get audio URL
      final audioUrl = _getSongAudioUrl(song);
      if (audioUrl == null) return false;
      
      // Set audio source with timeout
      await Future.any([
        audioPlayer.setUrl(audioUrl),
        Future.delayed(_timeout, () => throw TimeoutException('Timeout loading audio')),
      ]);
      
      // Get duration
      final duration = audioPlayer.duration;
      if (duration == null || duration.inSeconds <= 0) {
        return false;
      }
      
      // Update in database
      await _updateDurationInDatabase(song.id, duration.inSeconds);
      
      return true;
      
    } catch (e) {
      // Ignore individual song errors to not disrupt batch processing
      return false;
    } finally {
      // Always dispose audio player
      try {
        await audioPlayer?.dispose();
      } catch (e) {
        // Ignore disposal errors
      }
    }
  }

  /// Get audio URL for a song
  String? _getSongAudioUrl(Song song) {
    try {
      final pbService = PocketBaseService();
      
      if (song.audioFileName?.isNotEmpty == true) {
        return '${pbService.pb.baseUrl}/api/files/songs/${song.id}/${song.audioFileName}';
      } else {
        return '${pbService.pb.baseUrl}/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
      }
    } catch (e) {
      return null;
    }
  }

  /// Update song duration in database
  Future<void> _updateDurationInDatabase(String songId, int durationInSeconds) async {
    final pbService = PocketBaseService();
    await pbService.pb.collection('songs').update(songId, body: {
      'duration': durationInSeconds,
    });
  }

  /// Cancel current operation
  void cancelOperation() {
    if (state is! DurationLoading && state is! DurationProgress) return;
    
    state = const DurationState.cancelled();
  }

  /// Reset state to idle
  void resetState() {
    state = const DurationState.idle();
  }

  /// Alias for backward compatibility
  void reset() {
    resetState();
  }
}

/// Duration update states
abstract class DurationState {
  const DurationState();
  
  const factory DurationState.idle() = DurationIdle;
  const factory DurationState.loading() = DurationLoading;
  const factory DurationState.progress({
    required int current,
    required int total,
    required String currentSongTitle,
  }) = DurationProgress;
  const factory DurationState.completed({
    required int successCount,
    required int failCount,
    required String message,
  }) = DurationCompleted;
  const factory DurationState.error(String message) = DurationError;
  const factory DurationState.cancelled() = DurationCancelled;

  // Compatibility getters for existing UI
  bool get isUpdating => this is DurationLoading || this is DurationProgress;
  bool get isCompleted => this is DurationCompleted;
  String? get error => this is DurationError ? (this as DurationError).message : null;
  
  int get processedSongs => this is DurationProgress ? (this as DurationProgress).current : 0;
  int get totalSongs => this is DurationProgress ? (this as DurationProgress).total : 
                      this is DurationCompleted ? (this as DurationCompleted).successCount + (this as DurationCompleted).failCount : 0;
  
  String? get currentSongTitle => this is DurationProgress ? (this as DurationProgress).currentSongTitle : null;
  
  double get progress => this is DurationProgress ? (this as DurationProgress).progress : 0.0;
  
  int get successCount => this is DurationCompleted ? (this as DurationCompleted).successCount : 0;
  
  int get failCount => this is DurationCompleted ? (this as DurationCompleted).failCount : 0;
}

class DurationIdle extends DurationState {
  const DurationIdle();
}

class DurationLoading extends DurationState {
  const DurationLoading();
}

class DurationProgress extends DurationState {
  final int current;
  final int total;
  @override
  final String currentSongTitle;
  
  const DurationProgress({
    required this.current,
    required this.total,
    required this.currentSongTitle,
  });
  
  @override
  double get progress => total > 0 ? current / total : 0.0;
}

class DurationCompleted extends DurationState {
  @override
  final int successCount;
  @override
  final int failCount;
  final String message;
  
  const DurationCompleted({
    required this.successCount,
    required this.failCount,
    required this.message,
  });
}

class DurationError extends DurationState {
  final String message;
  const DurationError(this.message);
}

class DurationCancelled extends DurationState {
  const DurationCancelled();
}

/// Timeout exception for audio loading
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
} 