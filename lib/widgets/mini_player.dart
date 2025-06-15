import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';

import '../controllers/player_controller.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';
import '../utils/image_helpers.dart';
import '../utils/color_extractor.dart';
import '../providers/dynamic_color_provider.dart';
// Used for Song type in playerState.currentSong and MusicPlayerRoute
import '../models/song.dart';
import '../models/playlist.dart';
import '../repositories/song_playlist_repository.dart';
import '../services/pocketbase_service.dart';
import 'playlist_selection_modal.dart';

// Provider for playlist update notifications
final playlistUpdateNotifierProvider = StateNotifierProvider<PlaylistUpdateNotifier, int>((ref) {
  return PlaylistUpdateNotifier();
});

class PlaylistUpdateNotifier extends StateNotifier<int> {
  PlaylistUpdateNotifier() : super(0);

  void notifyPlaylistUpdated() {
    state++;
  }
}

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isLoadingPlaylists = false;
  bool _isInPlaylist = false;
  String? _lastCheckedSongId; // Cache to avoid unnecessary checks

  // Add cache for playlist data to reduce database calls
  static List<Playlist>? _cachedPlaylists;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  // Add optimistic state for immediate UI feedback
  bool _optimisticState = false;
  bool _hasOptimisticState = false;

  @override
  void initState() {
    super.initState();
    // Check playlist status after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfSongInPlaylist();
    });
  }

  @override
  void didUpdateWidget(MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only check if song actually changed
    final currentSong = ref.read(playerControllerProvider).currentSong;
    if (currentSong?.id != _lastCheckedSongId) {
      // Immediately update to loading state for better UX
      setState(() {
        _isLoadingPlaylists = true;
      });
      _checkIfSongInPlaylist();
    }
  }

  Future<void> _checkIfSongInPlaylist() async {
    final currentSong = ref.read(playerControllerProvider).currentSong;
    if (currentSong == null) return;
    
    // Avoid duplicate checks for the same song
    if (_lastCheckedSongId == currentSong.id && !_hasOptimisticState) {
      return;
    }

    try {
      // Reduced debug logging for better performance
      
      // Set loading state immediately for better UX
      if (mounted) {
        setState(() {
          _isLoadingPlaylists = true;
        });
      }
      
      List<Playlist> allPlaylists;
      
      // Use cache if available and valid
      final now = DateTime.now();
      if (_cachedPlaylists != null && 
          _cacheTimestamp != null && 
          now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0) {
        allPlaylists = _cachedPlaylists!;
      } else {
        final pbService = PocketBaseService();
        await pbService.initialize();
        final repository = SongPlaylistRepository(pbService);
        allPlaylists = await repository.getAllPlaylists();
        
        // Update cache
        _cachedPlaylists = allPlaylists;
        _cacheTimestamp = now;
      }
      
      bool foundInAnyPlaylist = false;
      
      for (final playlist in allPlaylists) {
        final containsSong = playlist.songs.contains(currentSong.id);
        if (containsSong) {
          foundInAnyPlaylist = true;
          break; // Early exit for better performance
        }
      }
      
      if (mounted) {
        setState(() {
          _isInPlaylist = foundInAnyPlaylist;
          _lastCheckedSongId = currentSong.id;
          _isLoadingPlaylists = false;
        });
        
        // Clear optimistic state now that we have real state
        _clearOptimisticState();
      }
    } catch (e) {
      // Reduced debug logging for better performance
      // Don't show error to user for this background check
      if (mounted) {
        setState(() {
          _isInPlaylist = false; // Default to false on error
          _lastCheckedSongId = currentSong.id;
          _isLoadingPlaylists = false;
        });
        
        // Clear optimistic state on error too
        _clearOptimisticState();
      }
    }
  }

  // Clear cache when playlists are modified
  static void _clearPlaylistCache() {
    _cachedPlaylists = null;
    _cacheTimestamp = null;
    // Reduced debug logging for better performance
  }

  Future<void> _showPlaylistModal(BuildContext context, Song song) async {
    // Reduced debug logging for better performance
    
    await showPlaylistSelectionModal(
      context,
      song,
      onPlaylistsChanged: () {
        // Clear cache to force refresh
        _clearPlaylistCache();
        
        // Force immediate refresh of button state
        _lastCheckedSongId = null; // Reset cache
        _checkIfSongInPlaylist();
      },
    );
  }

  // Method to set optimistic state immediately after user action
  void _setOptimisticState(bool state) {
    setState(() {
      _optimisticState = state;
      _hasOptimisticState = true;
    });
    // Reduced debug logging for better performance
  }

  void _clearOptimisticState() {
    if (_hasOptimisticState) {
      setState(() {
        _hasOptimisticState = false;
        _optimisticState = false;
      });
      // Reduced debug logging for better performance
    }
  }

  void _onSongChanged(Song? oldSong, Song? newSong) {
    if (oldSong?.id != newSong?.id) {
      // Reduced debug logging for better performance
      _lastCheckedSongId = null; // Reset cache for new song
      _checkIfSongInPlaylist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final dynamicColorState = ref.watch(dynamicColorProvider);
    final currentSong = playerState.currentSong;
    final colors = dynamicColorState.colors ?? ColorExtractor.getDefaultColors();
    
    // Watch for song changes to refresh button state with debouncing
    ref.listen(playerControllerProvider.select((state) => state.currentSong), (previous, next) {
      _onSongChanged(previous, next);
      
      // Auto-extract colors for new song
      if (next != null && previous?.id != next.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(dynamicColorProvider.notifier).extractColorsFromSong(next);
        });
      }
    });
    
    // Don't show mini player if no song is playing
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    // Auto-extract colors if not already extracted for current song
    if (dynamicColorState.currentSongId != currentSong.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dynamicColorProvider.notifier).extractColorsFromSong(currentSong);
      });
    }

    return GestureDetector(
      onTap: () {
        // Navigate to full player screen when mini player is tapped
        context.router.push(MusicPlayerRoute(song: currentSong));
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.backgroundStart, // Use album color directly
          border: Border(
            top: BorderSide(
                              color: colors.accent,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          children: [
            // Progress Bar
            SizedBox(
              height: 2,
              child: LinearProgressIndicator(
                value: playerState.currentPosition.inMilliseconds /
                    (currentSong.duration.inMilliseconds == 0 ? 1 : currentSong.duration.inMilliseconds),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: colors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            // Content
            Expanded(
              child: Row(
                children: [
                  // Album Art
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.greyDark,
                    ),
                    child: ImageHelpers.buildSafeNetworkImage(
                      imageUrl: currentSong.albumArtUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(4),
                      fallbackWidget: Container(
                        width: 48,
                        height: 48,
                        color: AppColors.greyDark,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // Song Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentSong.artist,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Control Buttons
                  Row(
                    children: [
                      // Add to Playlist Button
                      Consumer(
                        builder: (context, ref, child) {
                          // Use optimistic state if available, otherwise use real state
                          final displayState = _hasOptimisticState ? _optimisticState : _isInPlaylist;
                          
                          return IconButton(
                            onPressed: _isLoadingPlaylists ? null : () async {
                              final currentSong = ref.read(playerControllerProvider).currentSong;
                              if (currentSong != null) {
                                // Set optimistic state based on current state
                                // If currently in playlist, optimistically show it will be removed
                                // If not in playlist, optimistically show it will be added
                                final hasPlaylists = _cachedPlaylists?.isNotEmpty ?? true;
                                if (hasPlaylists) {
                                  _setOptimisticState(!displayState);
                                }
                                
                                await _showPlaylistModal(context, currentSong);
                                
                                // Clear optimistic state and refresh real state
                                _clearOptimisticState();
                                await _checkIfSongInPlaylist();
                              }
                            },
                            icon: _isLoadingPlaylists 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).iconTheme.color ?? Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  displayState ? Icons.check_circle : Icons.add_circle_outline,
                                  color: Colors.white,
                                ),
                            tooltip: _isLoadingPlaylists 
                              ? 'Checking playlists...'
                              : (displayState ? 'In playlist' : 'Add to playlist'),
                          );
                        },
                      ),
                      // Play/Pause Button
                      IconButton(
                        icon: Icon(
                          playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (playerState.isPlaying) {
                            ref.read(playerControllerProvider.notifier).pause();
                          } else {
                            ref.read(playerControllerProvider.notifier).resume();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
