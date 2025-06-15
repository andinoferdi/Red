import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import 'package:get_it/get_it.dart';
import '../../models/song.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/song_repository.dart';
import '../states/player_state.dart';
import 'play_history_controller.dart';

/// Provider for player controller
final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(ref),
);

/// Controller for handling music playback
class PlayerController extends StateNotifier<PlayerState> {
  late final AudioPlayer _audioPlayer;
  final Ref ref;
  Timer? _positionTimer;
  String? _currentAudioUrl;
  bool _isDisposed = false;
  
  PlayerController(this.ref) : super(PlayerState.initial()) {
    _initializeAudioPlayer();
  }
  
  /// Initialize audio player with error handling
  void _initializeAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      // Try to reinitialize after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          try {
            _audioPlayer = AudioPlayer();
            _initAudioPlayer();
          } catch (retryError) {
            debugPrint('Failed to reinitialize audio player: $retryError');
          }
        }
      });
    }
  }
  
  /// Recreate audio player to fix instance conflicts
  Future<void> _recreateAudioPlayer() async {
    if (_isDisposed) return;
    
    try {
      // Cancel position timer
      _positionTimer?.cancel();
      
      // Dispose current player
      await _audioPlayer.dispose();
      
      // Wait for cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Create new player
      _audioPlayer = AudioPlayer();
      
      // Reinitialize listeners
      _initAudioPlayer();
      
    } catch (e) {
      debugPrint('Error recreating audio player: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _positionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _initAudioPlayer() {
    // Listen to playback state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      
      if (processingState == ProcessingState.loading || 
          processingState == ProcessingState.buffering) {
        state = state.copyWith(isBuffering: true);
      } else {
        state = state.copyWith(
          isPlaying: isPlaying,
          isBuffering: false,
        );
        
        if (processingState == ProcessingState.completed) {
          _handleSongCompletion();
        }
      }
    });
    
    // Listen to duration changes to update song duration
    _audioPlayer.durationStream.listen((duration) {
      if (_isDisposed) return;
      
      if (duration != null && state.currentSong != null) {
        final updatedSong = _updateSongWithRealDuration(state.currentSong!, duration);
        state = state.copyWith(currentSong: updatedSong);
      }
    });
    
    // Listen to player errors
    _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      
      if (playerState.processingState == ProcessingState.idle && 
          !playerState.playing && 
          state.isBuffering) {
        // Reset buffering state if player becomes idle while buffering
        state = state.copyWith(isBuffering: false);
      }
    });
    
    // Start position update timer
    _positionTimer = Timer.periodic(const Duration(milliseconds:200), (_) {
      if (!_isDisposed && _audioPlayer.playing) {
        _updatePosition();
      }
    });
  }
  
  /// Update current position (separate method to handle async properly)
  void _updatePosition() {
    if (_isDisposed) return;
    
    try {
      final position = _audioPlayer.position;
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      // Ignore position update errors
    }
  }
  
  /// Update song with actual audio duration
  Song _updateSongWithRealDuration(Song song, Duration realDuration) {
    // Only update if the real duration is significantly different or if duration is 0
    if ((song.duration - realDuration).inSeconds.abs() > 5 || song.durationInSeconds == 0) {
      // Update the song duration in database if it's 0 or significantly different
      _updateDurationInDatabase(song.id, realDuration.inSeconds);
      
      return song.copyWith(durationInSeconds: realDuration.inSeconds);
    }
    return song;
  }

  /// Update song duration in PocketBase database
  Future<void> _updateDurationInDatabase(String songId, int durationInSeconds) async {
    try {
      final pbService = PocketBaseService();
      await pbService.pb.collection('songs').update(songId, body: {
        'duration': durationInSeconds,
      });
    } catch (e) {
      debugPrint('Error updating song duration in database: $e');
    }
  }
  
  /// Handle song completion based on repeat mode
  Future<void> _handleSongCompletion() async {
    if (_isDisposed) return;
    
    switch (state.repeatMode) {
      case RepeatMode.off:
        if (state.currentIndex < state.queue.length - 1) {
          await skipNext();
        } else {
          state = state.copyWith(
            isPlaying: false, 
            currentPosition: state.currentSong?.duration ?? Duration.zero
          );
        }
        break;
      case RepeatMode.all:
        if (state.currentIndex < state.queue.length - 1) {
          await skipNext();
        } else if (state.queue.isNotEmpty) {
          // Loop back to first song
          state = state.copyWith(currentIndex: 0);
          await playSong(state.queue[0]);
        }
        break;
      case RepeatMode.one:
        // Replay current song
        await seekTo(Duration.zero);
        break;
    }
  }
  
  /// Load song by ID and return Song object
  Future<Song> loadSongById(String songId) async {
    if (_isDisposed) throw Exception('Player is disposed');
    
    try {
      final pbService = PocketBaseService();
      final record = await pbService.pb.collection('songs').getOne(
        songId,
        expand: 'artist_id,album_id',
      );
      
      final song = Song.fromRecord(record);
      return song;
    } catch (e) {
      debugPrint('Error loading song by ID: $e');
      throw Exception('Failed to load song: $e');
    }
  }
  
  /// Core play song method that handles all playback logic
  Future<void> playSong(Song song, {bool forceRestart = false}) async {
    if (_isDisposed) return;
    
    try {
      // GLOBAL FORCE RESTART: Always restart if same song is clicked again
      final isCurrentSong = state.currentSong?.id == song.id;
      final shouldForceRestart = forceRestart || isCurrentSong;
      
      // Set buffering state immediately for better UX
      state = state.copyWith(
        isBuffering: true,
        currentSong: song,
      );
      
      // Get audio URL
      final audioUrl = await _getSongAudioUrl(song);
      
      // Check if song has changed during URL fetching
      if (state.currentSong?.id != song.id) {
        return;
      }
      
      // Check if this URL is already playing (unless forced restart)
      if (!shouldForceRestart && _currentAudioUrl == audioUrl && _audioPlayer.playing) {
        return;
      }
      
      // Stop current playback first
      try {
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Ignore stop errors, continue with playback
      }
      
      // Load and play new audio
      await _audioPlayer.setUrl(audioUrl);
      _currentAudioUrl = audioUrl;
      
      // Verify song hasn't changed during loading
      if (state.currentSong?.id != song.id) {
        return;
      }
      
      await _audioPlayer.play();
      
      // Add to play history
      _addToPlayHistory(song.id);
      
    } catch (e) {
      debugPrint('Error playing song "${song.title}": $e');
      
      // Try to handle specific errors
      if (e.toString().contains('AudioPlayer has already been disposed') ||
          e.toString().contains('Player instance')) {
        try {
          await _recreateAudioPlayer();
          
          // Wait a bit for the new player to initialize
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Check if song is still the same before retrying
          if (state.currentSong?.id == song.id) {
            final audioUrl = await _getSongAudioUrl(song);
            await _audioPlayer.setUrl(audioUrl);
            _currentAudioUrl = audioUrl;
            await _audioPlayer.play();
            
            _addToPlayHistory(song.id);
          }
        } catch (recreateError) {
          debugPrint('Failed to recreate player and play song: $recreateError');
          // Try fallback audio URL if recreation fails
          await _tryFallbackAudio(song);
        }
      } else {
        // Try fallback audio URL for other errors
        await _tryFallbackAudio(song);
      }
    }
  }

  /// Try fallback audio URL (demo file)
  Future<void> _tryFallbackAudio(Song song) async {
    try {
      const fallbackUrl = 'http://127.0.0.1:8090/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
      
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      await _audioPlayer.setUrl(fallbackUrl);
      _currentAudioUrl = fallbackUrl;
      await _audioPlayer.play();
      
      _addToPlayHistory(song.id);
      
    } catch (fallbackError) {
      debugPrint('Fallback audio also failed: $fallbackError');
      // Reset buffering state on complete failure
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }

  /// Get song audio URL with fallback
  Future<String> _getSongAudioUrl(Song song) async {
    try {
      final pbService = PocketBaseService();
      final baseUrl = pbService.pb.baseUrl;
      
      String url;
      if (song.audioFileName?.isNotEmpty == true) {
        url = '$baseUrl/api/files/songs/${song.id}/${song.audioFileName}';
      } else {
        // Fallback to demo file
        url = '$baseUrl/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
      }
      
      return url;
    } catch (e) {
      debugPrint('Error getting song audio URL: $e, using fallback');
      return 'http://127.0.0.1:8090/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }
  
  /// Resume playback
  Future<void> resume() async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }
  
  /// Toggle between play and pause
  Future<void> togglePlayPause() async {
    if (_isDisposed) return;
    
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }
  
  /// Skip to next song
  Future<void> skipNext() async {
    if (_isDisposed) return;
    
    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;
      
      if (queueLength == 0) {
        return;
      }
      
      int nextIndex;
      
      if (state.repeatMode == RepeatMode.one) {
        // Repeat current song
        nextIndex = currentIndex;
      } else if (currentIndex < queueLength - 1) {
        // Go to next song
        nextIndex = currentIndex + 1;
      } else if (state.repeatMode == RepeatMode.all) {
        // Loop back to first song
        nextIndex = 0;
      } else {
        // End of queue and no repeat
        return;
      }
      
      final nextSong = state.queue[nextIndex];
      
      state = state.copyWith(currentIndex: nextIndex);
      
      await playSong(nextSong);
    } catch (e) {
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Skip to previous song
  Future<void> skipPrevious() async {
    if (_isDisposed) return;
    
    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;
      
      if (queueLength == 0) {
        return;
      }
      
      int prevIndex;
      
      if (state.repeatMode == RepeatMode.one) {
        // Repeat current song
        prevIndex = currentIndex;
      } else if (currentIndex > 0) {
        // Go to previous song
        prevIndex = currentIndex - 1;
      } else if (state.repeatMode == RepeatMode.all) {
        // Loop to last song
        prevIndex = queueLength - 1;
      } else {
        // Beginning of queue and no repeat
        return;
      }
      
      final prevSong = state.queue[prevIndex];
      
      state = state.copyWith(currentIndex: prevIndex);
      
      await playSong(prevSong);
    } catch (e) {
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Seek to a position
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.seek(position);
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      debugPrint('Error seeking to position: $e');
    }
  }
  
  /// Set queue and play, with playlist context
  Future<void> playQueueFromPlaylist(List<Song> songs, int startIndex, String playlistId) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    
    final songToPlay = songs[startIndex];
    final isCurrentSong = state.currentSong?.id == songToPlay.id;
    final isDifferentContext = state.currentPlaylistId != playlistId;
    
    // Force restart if same song but different context (e.g., from search to playlist)
    final shouldForceRestart = isCurrentSong && isDifferentContext;
    
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: playlistId,
    );
    
    await playSong(songToPlay, forceRestart: shouldForceRestart);
  }

  /// Set queue and play (no playlist context)
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    
    final songToPlay = songs[startIndex];
    final isCurrentSong = state.currentSong?.id == songToPlay.id;
    final isDifferentContext = state.currentPlaylistId != null;
    
    // Force restart if same song but different context (e.g., from playlist to search)
    final shouldForceRestart = isCurrentSong && isDifferentContext;
    
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: null,
    );
    
    await playSong(songToPlay, forceRestart: shouldForceRestart);
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
    if (_isDisposed) return;
    
    final newShuffleMode = !state.shuffleMode;
    state = state.copyWith(shuffleMode: newShuffleMode);
    
    if (newShuffleMode) {
      // Check if playing from playlist or individual song
      if (state.currentPlaylistId != null && state.queue.isNotEmpty) {
        // Playlist shuffle: shuffle current playlist queue
        _shuffleCurrentQueue();
      } else {
        // General shuffle: shuffle all songs from database
        _shuffleAllSongs();
      }
    }
  }
  
  /// Shuffle current queue (for playlist context)
  void _shuffleCurrentQueue() {
    if (state.queue.isEmpty) return;
    
    final currentSong = state.currentSong;
    final List<Song> shuffledQueue = List.from(state.queue)..shuffle();
    
    if (currentSong != null) {
      shuffledQueue.remove(currentSong);
      shuffledQueue.insert(0, currentSong);
    }
    
    state = state.copyWith(
      queue: shuffledQueue,
      currentIndex: 0,
    );
  }
  
  /// Shuffle all songs from database (for general shuffle)
  Future<void> _shuffleAllSongs() async {
    try {
      final songRepository = GetIt.instance<SongRepository>();
      final allSongs = await songRepository.getAllSongs();
      
      if (allSongs.isEmpty) return;
      
      // Shuffle all songs
      final List<Song> shuffledSongs = List.from(allSongs)..shuffle();
      
      // Keep current song as first if it exists in the list
      final currentSong = state.currentSong;
      if (currentSong != null) {
        shuffledSongs.remove(currentSong);
        shuffledSongs.insert(0, currentSong);
      }
      
      // Update state with shuffled queue
      state = state.copyWith(
        queue: shuffledSongs,
        currentIndex: 0,
        currentPlaylistId: null, // Clear playlist context for general shuffle
      );
      
    } catch (e) {
      debugPrint('Error shuffling all songs: $e');
      // Fallback to current queue shuffle if available
      if (state.queue.isNotEmpty) {
        _shuffleCurrentQueue();
      }
    }
  }
  
  /// Toggle repeat mode
  void toggleRepeatMode() {
    if (_isDisposed) return;
    
    switch (state.repeatMode) {
      case RepeatMode.off:
        state = state.copyWith(repeatMode: RepeatMode.all);
        break;
      case RepeatMode.all:
        state = state.copyWith(repeatMode: RepeatMode.one);
        break;
      case RepeatMode.one:
        state = state.copyWith(repeatMode: RepeatMode.off);
        break;
    }
  }
  
  /// Add song to queue
  void addToQueue(Song song) {
    if (_isDisposed) return;
    
    final newQueue = List<Song>.from(state.queue)..add(song);
    state = state.copyWith(queue: newQueue);
  }
  
  /// Remove song from queue
  void removeFromQueue(int index) {
    if (_isDisposed) return;
    
    if (index < 0 || index >= state.queue.length) {
      return;
    }
    
    final newQueue = List<Song>.from(state.queue)..removeAt(index);
    
    // Adjust current index if needed
    int newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      // Stop playback if current song is removed
      if (newQueue.isEmpty) {
        _audioPlayer.stop();
        state = state.copyWith(
          queue: newQueue,
          currentSong: null,
          isPlaying: false,
          currentIndex: -1,
        );
        return;
      }
      
      // Play next song if available
      if (newIndex >= newQueue.length) {
        newIndex = newQueue.length - 1;
      }
      
      // Prepare to play the new song
      final newSong = newQueue[newIndex];
      state = state.copyWith(
        queue: newQueue,
        currentIndex: newIndex,
        currentSong: newSong,
      );
      playSong(newSong); // No force restart needed for queue removal
      return;
    }
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
    );
  }

  void pauseSong() {
    if (_isDisposed) return;
    
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  void resumeSong() {
    if (_isDisposed) return;
    
    if (!state.isPlaying && state.currentSong != null) {
      state = state.copyWith(isPlaying: true);
    }
  }

  /// Stop playback and reset player state
  Future<void> stopAndReset() async {
    if (_isDisposed) return;
    
    try {
      // Stop audio player
      await _audioPlayer.stop();
      
      // Clear current audio URL
      _currentAudioUrl = null;
      
      // Reset state to initial values
      state = PlayerState.initial();
      
    } catch (e) {
      debugPrint('Error stopping and resetting player: $e');
      // Force reset state even if stop fails
      _currentAudioUrl = null;
      state = PlayerState.initial();
    }
  }

  void skipToNext() {
    if (_isDisposed) return;
    
    // Use the proper skipNext implementation
    skipNext();
  }
  
  /// Add song to play history
  void _addToPlayHistory(String songId) {
    try {
      // Add to play history without waiting for completion
      ref.read(playHistoryControllerProvider.notifier).addPlayHistory(songId);
    } catch (e) {
      debugPrint('Error adding to play history: $e');
      // Don't throw error, just log it
    }
  }

  /// Debug helper to track currentPlaylistId state
  void debugCurrentPlaylistId() {
    // Reduced debug logging for better performance
  }
  
  /// Play song without playlist context (for individual song playback)
  Future<void> playSongWithoutPlaylist(Song song, {bool forceRestart = false}) async {
    if (_isDisposed) return;
    
    final isCurrentSong = state.currentSong?.id == song.id;
    final isDifferentContext = state.currentPlaylistId != null;
    
    // GLOBAL FORCE RESTART: Always restart if same song is clicked again
    // Also force restart if different context (e.g., from playlist to search)
    // OR if explicitly requested
    final shouldForceRestart = forceRestart || isCurrentSong || (isCurrentSong && isDifferentContext);
    
    // Only reset shuffle mode if not in general shuffle mode
    // General shuffle should persist when playing individual songs
    final shouldResetShuffle = state.shuffleMode && state.currentPlaylistId != null;
    
    if (shouldResetShuffle) {
      state = state.copyWith(shuffleMode: false);
    }
    
    // If shuffle is active and no playlist context, keep the shuffled queue
    // Otherwise, set single song queue
    if (state.shuffleMode && state.currentPlaylistId == null) {
      // Keep current shuffled queue, just update current song if needed
      final songIndex = state.queue.indexWhere((s) => s.id == song.id);
      if (songIndex != -1) {
        state = state.copyWith(
          currentIndex: songIndex,
          currentPlaylistId: null,
        );
      } else {
        // Song not in current queue, add it and play
        final newQueue = [song, ...state.queue];
        state = state.copyWith(
          queue: newQueue,
          currentIndex: 0,
          currentPlaylistId: null,
        );
      }
    } else {
      // Clear playlist context and set single song queue
      state = state.copyWith(
        queue: [song],
        currentIndex: 0,
        currentPlaylistId: null,
      );
    }
    
    await playSong(song, forceRestart: shouldForceRestart);
  }
  
  /// Play song by ID without playlist context (for individual song playback)
  Future<void> playSongByIdWithoutPlaylist(String songId) async {
    if (_isDisposed) return;
    
    try {
      // CRITICAL: Clear cache to ensure fresh data loading and avoid old collection IDs
      SongRepository.clearCache();
      debugPrint('🔄 Cleared song cache for fresh data loading');
      
      // ENHANCED: Use improved song repository with caching
      final songRepository = GetIt.instance<SongRepository>();
      
      // Use the new getSongById method which checks cache first, then loads from database
      final song = await songRepository.getSongById(songId);
      
      if (song == null) {
        debugPrint('❌ Song not found with ID: $songId');
        // Reset buffering state on error
        if (!_isDisposed) {
          state = state.copyWith(isBuffering: false);
        }
        return;
      }
      
      
  
      
      await playSongWithoutPlaylist(song);
    } catch (e) {
      debugPrint('❌ Error loading song by ID: $e');
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Update the current queue and index (for shuffle functionality)
  void updateQueue(List<Song> newQueue, int newIndex) {
    if (_isDisposed) return;
    
    // Validate new index
    if (newIndex < 0 || newIndex >= newQueue.length) {
      return;
    }
    
    final newCurrentSong = newQueue[newIndex];
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
      currentSong: newCurrentSong,
    );
  }
}


