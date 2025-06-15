import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import '../../utils/app_colors.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/song_playlist_repository.dart';
import '../../models/song.dart';
import '../../widgets/playlist_image_widget.dart';

import 'add_songs_screen.dart';
import 'edit_playlist_screen.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/mini_player.dart';

import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/song_item_widget.dart';
import '../../utils/image_helpers.dart';
import '../../providers/playlist_provider.dart';
import '../../widgets/animated_sound_bars.dart';

@RoutePage()
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final RecordModel playlist;
  final VoidCallback? onPlaylistUpdated;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    this.onPlaylistUpdated,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  bool _isLoading = true;
  List<Song> _songs = [];
  String? _errorMessage;
  late RecordModel _currentPlaylist;
  RecordModel? _creatorUser;
  bool _isLoadingCreator = true;
  
  // Recommended songs
  List<Song> _recommendedSongs = [];
  bool _isLoadingRecommended = false;
  final Set<String> _addingSongIds = {};
  
  // Track the last song played from recommended section
  String? _lastRecommendedSongId;
  
  // Force rebuild counter for playlist image
  int _imageRebuildCounter = 0;
  
  // Guard to prevent infinite recursion in refresh system
  bool _isRefreshing = false;
  
  // Note: Shuffle state is now managed by PlayerController

  @override
  void initState() {
    super.initState();
    _currentPlaylist = widget.playlist;
    _initializeData();
    
    // Initialize global playlist state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playlistProvider.notifier).loadPlaylists();
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _isLoadingRecommended = true;
      _isLoadingCreator = true;
    });

    try {
      // Fetch playlist songs first, then use for filtering recommendations
      final playlistSongs = await _getPlaylistSongsData();
      final results = await Future.wait([
        Future.value(playlistSongs), // Already fetched
        _getRecommendedSongsData(playlistSongs), // Pass songs for filtering
        _getCreatorInfoData(),
      ]);
      
      if (mounted) {
        setState(() {
          _songs = results[0] as List<Song>;
          _recommendedSongs = results[1] as List<Song>;
          _creatorUser = results[2] as RecordModel?;
          _isLoading = false;
          _isLoadingRecommended = false;
          _isLoadingCreator = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
          _isLoadingRecommended = false;
          _isLoadingCreator = false;
        });
      }
    }
  }

  Future<void> _fetchPlaylistSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songs = await _getPlaylistSongsData();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {

      setState(() {
        _errorMessage = 'Failed to load songs: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<List<Song>> _getPlaylistSongsData() async {
    final pbService = PocketBaseService();
    await pbService.initialize();
    
    final repository = SongPlaylistRepository(pbService);
    return await repository.getPlaylistSongs(_currentPlaylist.id);
  }



  Future<RecordModel?> _getCreatorInfoData() async {
    final pbService = PocketBaseService();
    await pbService.initialize();

    final creatorId = _currentPlaylist.data['user_id'] as String?;
    if (creatorId != null && creatorId.isNotEmpty) {
      return await pbService.pb.collection('users').getOne(creatorId);
    }
    return null;
  }

  Future<void> _fetchRecommendedSongs() async {
    setState(() {
      _isLoadingRecommended = true;
    });

    try {
      final recommended = await _getRecommendedSongsData();
      setState(() {
        _recommendedSongs = recommended;
        _isLoadingRecommended = false;
      });
    } catch (e) {

      setState(() {
        _recommendedSongs = [];
        _isLoadingRecommended = false;
      });
    }
  }

  Future<List<Song>> _getRecommendedSongsData([List<Song>? playlistSongs]) async {
    final pbService = PocketBaseService();
    await pbService.initialize();
    
    // Get all songs from database with expanded artist and album data
    final allSongsResult = await pbService.pb.collection('songs').getList(
      page: 1,
      perPage: 100,
      sort: '@random', // Random sort for variety
      expand: 'artist_id,album_id', // Expand artist and album relations
    );
    
    // Use provided songs or current _songs for filtering
    final songsToFilter = playlistSongs ?? _songs;
    
    // Convert to Song objects and filter out songs already in playlist
    final currentSongIds = songsToFilter.map((song) => song.id).toSet();
    final allSongs = allSongsResult.items.map((record) => Song.fromRecord(record)).toList();
    final filteredSongs = songsToFilter.isEmpty 
        ? allSongs // If playlist is empty, show all songs
        : allSongs.where((song) => !currentSongIds.contains(song.id)).toList();
    
    // Take first 10 songs as recommendations
    return filteredSongs.take(10).toList();
  }

  void _showEditPlaylistDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlaylistScreen(playlist: _currentPlaylist),
      ),
    );
    
    // If changes were made, refresh the playlist
    if (result == true) {
      // Force complete refresh of all components
      await _forceCompleteRefresh();
      widget.onPlaylistUpdated?.call();
    }
  }

  /// Force complete refresh of all playlist components
  Future<void> _forceCompleteRefresh() async {
    // Prevent infinite recursion
    if (_isRefreshing) {

      return;
    }
    
    _isRefreshing = true;
    
    
    try {
      // Clear all caches to force complete reload
      PlaylistImageWidget.clearCache(_currentPlaylist.id);
      PlaylistImageWidget.clearAllCache(); // Clear all cache to be sure
      
      // Clear mini player cache if it exists (import required at top of file)
      // This ensures mini player also reflects updated playlist image
      try {
        final miniPlayerCache = ref.read(playlistUpdateNotifierProvider.notifier);
        miniPlayerCache.notifyPlaylistUpdated();
      } catch (e) {

      }

      final pbService = PocketBaseService();
      await pbService.initialize();
      
      // First refresh the playlist data
      final updatedPlaylist = await pbService.pb
          .collection('playlists')
          .getOne(_currentPlaylist.id);
      
      // Fetch playlist songs first, then use it for recommendations
      final playlistSongs = await _getPlaylistSongsData();
      final results = await Future.wait([
        Future.value(playlistSongs), // Already fetched
        _getRecommendedSongsData(playlistSongs), // Pass songs for filtering
        _getCreatorInfoData(),
      ]);
      
      // Single setState to update everything at once
      if (mounted) {
        setState(() {
          _currentPlaylist = updatedPlaylist;
          _songs = results[0] as List<Song>;
          _recommendedSongs = results[1] as List<Song>;
          _creatorUser = results[2] as RecordModel?;
          _isLoading = false;
          _isLoadingRecommended = false;
          _isLoadingCreator = false;
          _imageRebuildCounter++; // Only increment once
        });
      }
      
      
          } catch (e) {
      
      // Reset loading states even on error
      setState(() {
        _isLoading = false;
        _isLoadingRecommended = false;
        _isLoadingCreator = false;
      });
    } finally {
      // Always reset the refreshing flag
      _isRefreshing = false;
    }
  }



  Future<void> _navigateToAddSongs() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddSongsScreen(playlist: _currentPlaylist),
      ),
    );

    // If songs were added successfully, refresh all components
    if (result == true) {

      await _forceCompleteRefresh();
    }
  }

  Future<void> _addSongToPlaylist(Song song) async {
    setState(() {
      _addingSongIds.add(song.id);
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      
      final repository = SongPlaylistRepository(pbService);
      await repository.addSongToPlaylist(
        widget.playlist.id,
        song.id,
      );

      // Clear playlist image cache to force mosaic update
      PlaylistImageWidget.clearCache(_currentPlaylist.id);
      
      // Fetch updated playlist songs first, then use for filtering recommendations
      final updatedPlaylistSongs = await _getPlaylistSongsData();
      final updatedRecommendedSongs = await _getRecommendedSongsData(updatedPlaylistSongs);
      
      // Update state with fresh data
      setState(() {
        _songs = updatedPlaylistSongs;
        _recommendedSongs = updatedRecommendedSongs;
        _imageRebuildCounter++;
      });
      
      // Notify global playlist provider about update
      ref.read(playlistProvider.notifier).notifyPlaylistSongsChanged(_currentPlaylist.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${song.title} berhasil ditambahkan',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan lagu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _addingSongIds.remove(song.id);
      });
    }
  }

  /// Play song (show in mini player, don't navigate)
  void _playSong(Song song) {
    final playerState = ref.read(playerControllerProvider);
    List<Song> playQueue;
    int startIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with selected song at index 0
      playQueue = List.from(_songs);
      playQueue.shuffle();
      
      // Move selected song to first position
      playQueue.removeWhere((s) => s.id == song.id);
      playQueue.insert(0, song);
      startIndex = 0;
    } else {
      // Use original order
      playQueue = List.from(_songs);
      startIndex = _songs.indexOf(song);
    }

    ref.read(playerControllerProvider.notifier).playQueueFromPlaylist(playQueue, startIndex, _currentPlaylist.id);
  }

  /// Toggle shuffle mode
  void _toggleShuffle() {
    final playerState = ref.read(playerControllerProvider);
    
    // Only allow shuffle toggle if playing from this playlist or no playlist context
    if (playerState.currentPlaylistId == null || playerState.currentPlaylistId == _currentPlaylist.id) {
      ref.read(playerControllerProvider.notifier).toggleShuffle();
      
      // If currently playing from this playlist, update the queue accordingly
      if (playerState.currentPlaylistId == _currentPlaylist.id && playerState.currentSong != null) {
        _updateShuffleForCurrentPlayback();
      }
    }
  }

  /// Update shuffle for current playback
  void _updateShuffleForCurrentPlayback() {
    final playerState = ref.read(playerControllerProvider);
    final currentSong = playerState.currentSong;
    if (currentSong == null) return;

    // Find current song index in original list
    final currentIndex = _songs.indexWhere((song) => song.id == currentSong.id);
    if (currentIndex == -1) return;

    List<Song> newQueue;
    int newIndex;

    if (playerState.shuffleMode) {
      // Create shuffled queue with current song at index 0
      newQueue = List.from(_songs);
      newQueue.shuffle();
      
      // Move current song to first position
      newQueue.removeWhere((song) => song.id == currentSong.id);
      newQueue.insert(0, currentSong);
      newIndex = 0;
    } else {
      // Restore original order
      newQueue = List.from(_songs);
      newIndex = currentIndex;
    }

    // Update player queue
    ref.read(playerControllerProvider.notifier).updateQueue(newQueue, newIndex);
  }

  /// Play all songs in playlist starting from first
  void _playAllSongs() {
    if (_songs.isEmpty) return;
    
    final playerState = ref.read(playerControllerProvider);
    final currentPlaylistId = playerState.currentPlaylistId;
    
    // If currently playing from this playlist, pause/resume
    if (currentPlaylistId == _currentPlaylist.id) {
      if (playerState.isPlaying) {
        // Pause current playback
        ref.read(playerControllerProvider.notifier).pause();
      } else {
        // Resume current playback
        ref.read(playerControllerProvider.notifier).resume();
      }
    } else {
      // Prepare queue based on shuffle setting
      List<Song> playQueue;
      int startIndex;

      if (playerState.shuffleMode) {
        // Create shuffled queue
        playQueue = List.from(_songs);
        playQueue.shuffle();
        startIndex = 0;
      } else {
        // Use original order
        playQueue = List.from(_songs);
        startIndex = 0;
      }

      // Start playing with prepared queue
      ref.read(playerControllerProvider.notifier).playQueueFromPlaylist(playQueue, startIndex, _currentPlaylist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    
    // Watch auto-refresh playlist provider for automatic updates
    ref.watch(autoRefreshPlaylistProvider);
    
    // Auto-refresh when global playlist state changes
    ref.listen(playlistProvider, (previous, next) {
      if (previous?.lastUpdated != next.lastUpdated && !_isRefreshing) {

        _forceCompleteRefresh();
      }
    });
    
    // Listen for player state changes to reset recommended tracking
    ref.listen(playerControllerProvider, (previous, next) {
      // Reset recommended tracking if song changes and it's not from recommended
      if (previous?.currentSong?.id != next.currentSong?.id) {
        // If new song is not the last recommended song, clear the tracking
        if (_lastRecommendedSongId != null && _lastRecommendedSongId != next.currentSong?.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _lastRecommendedSongId = null;
              });
            }
          });
        }
      }
    });

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildPlaylistInfo(),
                ),
                SliverToBoxAdapter(
                  child: _buildPlayButton(),
                ),
                _buildSongsList(),
                // Recommended songs section
                SliverToBoxAdapter(
                  child: _buildRecommendedSongsSection(),
                ),
                // Add bottom spacing for navigation bar and mini player
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 70 + bottomPadding + (playerState.currentSong != null ? 64 : 0),
                  ),
                ),
              ],
            ),
          ),
          // Show mini player if there's a current song
          if (playerState.currentSong != null)
            const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2, // Library tab index
        bottomPadding: bottomPadding,
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[900]!,
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              margin: const EdgeInsets.only(top: 60),
              child: PlaylistImageWidget(
                key: ValueKey('playlist_image_${_currentPlaylist.id}_${_currentPlaylist.updated}_$_imageRebuildCounter'),
                playlist: _currentPlaylist,
                size: 200,
                borderRadius: 4,
                showMosaicForEmptyPlaylists: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorAvatar() {
    if (_isLoadingCreator) {
      return CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[700],
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    final avatarUrl = _creatorUser?.data['avatar'] as String?;
    final pbService = PocketBaseService();
    
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty && _creatorUser != null) {
      try {
        final imageUrl = pbService.pb.files.getUrl(_creatorUser!, avatarUrl).toString();

        return CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[700],
          child: ImageHelpers.buildSafeNetworkImage(
            imageUrl: imageUrl,
            width: 24,
            height: 24,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
            showLoadingIndicator: true,
            fallbackWidget: const Icon(
              Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
        );
      } catch (e) {
        // Fall through to default avatar
      }
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey[700],
      child: const Icon(
        Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildCreatorText() {
    if (_isLoadingCreator) {
      return Text(
        'Loading...',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Get the creator's name from the user record
    final name = _creatorUser?.data['name'] as String?;
    final username = _creatorUser?.data['username'] as String?;
    
    // Use 'name' field first, fallback to 'username', then 'Unknown User'
    final displayName = name?.isNotEmpty == true 
        ? name!
        : (username?.isNotEmpty == true ? username! : 'Unknown User');

    return Text(
      'Dibuat oleh $displayName',
      style: TextStyle(
        color: Colors.grey[400],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentPlaylist.data['name'] ?? 'Playlist Tanpa Judul',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _showEditPlaylistDialog,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currentPlaylist.data['description']?.isNotEmpty == true) ...[
            Text(
              _currentPlaylist.data['description'],
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildCreatorAvatar(),
              const SizedBox(width: 8),
              _buildCreatorText(),
              const SizedBox(width: 16),
              Text(
                '${_songs.length} lagu',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    return Consumer(
      builder: (context, ref, child) {
        final playerState = ref.watch(playerControllerProvider);
        final currentPlaylistId = playerState.currentPlaylistId;
        
        // Only consider as "playlist playing" if currently playing from THIS playlist
        final isPlayingFromThisPlaylist = currentPlaylistId == _currentPlaylist.id;
        final isPlaylistPlaying = isPlayingFromThisPlaylist && 
                                 _songs.any((song) => song.id == playerState.currentSong?.id);
        
        // Reduced debug logging for better performance
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _songs.isNotEmpty ? _playAllSongs : null,
                  icon: Icon(
                    isPlaylistPlaying && playerState.isPlaying 
                        ? Icons.pause 
                        : Icons.play_arrow, 
                    color: Colors.white,
                  ),
                  label: Text(
                    isPlaylistPlaying && playerState.isPlaying ? 'Jeda' : 'Putar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _toggleShuffle,
                icon: Icon(
                  Icons.shuffle, 
                  color: playerState.shuffleMode ? Colors.red : Colors.white,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: playerState.shuffleMode ? Colors.red.withValues(alpha: 0.2) : Colors.grey[800],
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _navigateToAddSongs,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongsList() {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: Colors.red),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchPlaylistSongs,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_songs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Playlist masih kosong',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan lagu untuk memulai atau pilih dari rekomendasi di bawah',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToAddSongs,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Tambah Lagu',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final song = _songs[index];
          
          return Consumer(
            builder: (context, ref, child) {
              final playerState = ref.watch(playerControllerProvider);
              final currentPlaylistId = playerState.currentPlaylistId;
              
              // STRICT CHECKING: Only show as "playing" if:
              // 1. Song is currently playing
              // 2. CurrentPlaylistId matches THIS playlist (not null)
              // 3. Song is in current queue at correct position
              
              final isCurrentSong = playerState.currentSong?.id == song.id;
              final isPlayingFromThisPlaylist = currentPlaylistId != null && 
                                               currentPlaylistId == _currentPlaylist.id;
              
              // CRITICAL: Only show as playing if song is playing FROM THIS PLAYLIST
              // If currentPlaylistId is null OR different from this playlist, don't show as playing
              
              final shouldShowAsPlaying = isCurrentSong && 
                                        isPlayingFromThisPlaylist && 
                                        playerState.isPlaying;
              
              // Additional validation: Check queue position to prevent race conditions
              bool isActuallyPlayingFromQueue = false;
              if (shouldShowAsPlaying && playerState.queue.isNotEmpty) {
                final currentIndex = playerState.currentIndex;
                if (currentIndex >= 0 && currentIndex < playerState.queue.length) {
                  final queueSong = playerState.queue[currentIndex];
                  isActuallyPlayingFromQueue = queueSong.id == song.id;
                }
              }
              
              // FINAL CHECK: All conditions must be true
              final isPlaying = shouldShowAsPlaying && isActuallyPlayingFromQueue;
              
              // Note: Race condition fix is working correctly - song playing without playlist context is properly handled
              
              return SongItemWidget(
                song: song,
                isCurrentSong: isCurrentSong && isPlayingFromThisPlaylist,
                isPlaying: isPlaying,
                onTap: () => _playSong(song),
                index: index + 1,
              );
            },
          );
        },
        childCount: _songs.length,
      ),
    );
  }

  Widget _buildRecommendedSongsSection() {
    // Always show recommendations, especially when playlist is empty
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        // Header with title and reload button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Lagu yang Direkomendasikan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Reload button
              ElevatedButton.icon(
                onPressed: _isLoadingRecommended ? null : _fetchRecommendedSongs,
                icon: _isLoadingRecommended
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.black, size: 18),
                label: const Text(
                  'Muat ulang',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recommended songs list
        _buildRecommendedSongsList(),
      ],
    );
  }

  Widget _buildRecommendedSongsList() {
    if (_isLoadingRecommended) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    if (_recommendedSongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.music_note,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada rekomendasi tersedia',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recommendedSongs.map((song) => _buildRecommendedSongItem(song)).toList(),
    );
  }

  Widget _buildRecommendedSongItem(Song song) {
    final isAdding = _addingSongIds.contains(song.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Consumer(
        builder: (context, ref, child) {
          final playerState = ref.watch(playerControllerProvider);
          final currentPlaylistId = playerState.currentPlaylistId;
          
          // For recommended songs, only show as playing if:
          // 1. Song is currently playing
          // 2. Song was the last one clicked from recommended section
          
          final isCurrentSong = playerState.currentSong?.id == song.id;
          final isLastRecommendedSong = _lastRecommendedSongId == song.id;
          
          // Only show as playing if this song was clicked from recommended AND is currently playing
          final isPlayingFromRecommended = isCurrentSong && 
                                         isLastRecommendedSong &&
                                         playerState.isPlaying;
          
          final isPlaying = isPlayingFromRecommended;
          
          // DEBUG: Log the state for troubleshooting animated bars
          if (isCurrentSong) {
            print('🎵 RECOMMENDED BARS: Song ${song.title} - isCurrentSong: $isCurrentSong, isLastRecommended: $isLastRecommendedSong, playerIsPlaying: ${playerState.isPlaying}, finalIsPlaying: $isPlaying');
          }
          
          return SongItemWidget(
            song: song,
            subtitle: song.artist.isNotEmpty ? song.artist : 'Unknown Artist',
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            isCurrentSong: isPlayingFromRecommended,
            isPlaying: isPlaying,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show animated sound bars if playing
                if (isPlaying)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: AnimatedSoundBars(
                      color: Colors.red,
                      size: 20.0,
                      isAnimating: true,
                    ),
                  ),
                // Show loading or add button
                isAdding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _addSongToPlaylist(song),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                      ),
              ],
            ),
            onTap: () {
              // Check if this is the same song currently playing
              final playerState = ref.read(playerControllerProvider);
              final isCurrentSong = playerState.currentSong?.id == song.id;
              
              // Track that this song was played from recommended section BEFORE playing
              // This ensures the tracking is set when the player state updates
              _lastRecommendedSongId = song.id;
              
              // Force a rebuild to update the UI immediately
              setState(() {});
              
              // Always play with force restart if same song (like playlist behavior)
              // This ensures song restarts from beginning when clicked from recommended
              ref.read(playerControllerProvider.notifier).playSongWithoutPlaylist(song, forceRestart: isCurrentSong);
            },
          );
        },
      ),
    );
  }
}


