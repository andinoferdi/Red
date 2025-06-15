import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../services/pocketbase_service.dart';
import '../repositories/song_playlist_repository.dart';
import '../utils/app_colors.dart';
import 'playlist_image_widget.dart';

// Import the provider from mini_player
import 'mini_player.dart' show playlistUpdateNotifierProvider;

class PlaylistSelectionModal extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback? onPlaylistsChanged;

  const PlaylistSelectionModal({
    super.key,
    required this.song,
    this.onPlaylistsChanged,
  });

  @override
  ConsumerState<PlaylistSelectionModal> createState() => _PlaylistSelectionModalState();
}

class _PlaylistSelectionModalState extends ConsumerState<PlaylistSelectionModal> {
  List<Playlist> _playlists = [];
  Map<String, bool> _playlistStates = {};
  bool _isLoading = true;
  bool _isApplyingChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);
      
      final playlists = await repository.getAllPlaylists();
      
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _playlistStates = {};
          
          // Initialize playlist states
          for (final playlist in playlists) {
            _playlistStates[playlist.id] = playlist.songs.contains(widget.song.id);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🎵 PLAYLIST_MODAL: Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load playlists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get playlist artwork
  Widget _buildPlaylistArtwork(Playlist playlist) {
    // Convert Playlist to RecordModel-like structure for the unified widget
    // This is a temporary approach until we unify the playlist data models
    final fakeRecord = _createFakeRecordFromPlaylist(playlist);
    
    return PlaylistImageWidget(
      playlist: fakeRecord,
      size: 48,
      borderRadius: 4,
      showMosaicForEmptyPlaylists: true,
    );
  }
  
  // Temporary helper to convert Playlist to RecordModel-like structure
  dynamic _createFakeRecordFromPlaylist(Playlist playlist) {
    return _FakeRecord(
      id: playlist.id,
      data: {
        'name': playlist.name,
        'cover_image': playlist.imageUrl ?? '',
        'songs': playlist.songs,
      },
    );
  }





  Future<void> _applyChanges() async {
    if (_isApplyingChanges) return;
    
    setState(() {
      _isApplyingChanges = true;
    });

    try {
      final pbService = PocketBaseService();
      await pbService.initialize();
      final repository = SongPlaylistRepository(pbService);

      bool hasChanges = false;
      int addedCount = 0;
      int removedCount = 0;

      for (final playlist in _playlists) {
        final currentState = _playlistStates[playlist.id] ?? false;
        final originalState = playlist.songs.contains(widget.song.id);

        if (currentState != originalState) {
          hasChanges = true;
          if (currentState) {
            // Add song to playlist
            await repository.addSongToPlaylist(playlist.id, widget.song.id);
            addedCount++;
          } else {
            // Remove song from playlist
            await repository.removeSongFromPlaylist(playlist.id, widget.song.id);
            removedCount++;
          }
        }
      }

      if (hasChanges) {
        // Notify playlist update
        ref.read(playlistUpdateNotifierProvider.notifier).notifyPlaylistUpdated();
        widget.onPlaylistsChanged?.call();
        
        // Show success message
        String message = '';
        if (addedCount > 0 && removedCount > 0) {
          message = 'Added to $addedCount, removed from $removedCount playlists';
        } else if (addedCount > 0) {
          message = 'Added to $addedCount playlist${addedCount > 1 ? 's' : ''}';
        } else if (removedCount > 0) {
          message = 'Removed from $removedCount playlist${removedCount > 1 ? 's' : ''}';
        }

        if (mounted && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('🎵 PLAYLIST_MODAL: Error applying changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingChanges = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.text,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 16),
                
                // Title and song info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add to playlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.song.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Done button
                TextButton(
                  onPressed: _isApplyingChanges ? null : _applyChanges,
                  child: _isApplyingChanges
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ],
            ),
          ),
          
          // Recently played section (if playlists exist)
          if (_playlists.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              height: 1,
              color: AppColors.textSecondary.withValues(alpha: 0.2),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Recently created',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: Show all playlists or sort options
                    },
                    child: Text(
                      'Show all',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Playlist list
          Expanded(
            child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : _playlists.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.queue_music,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No playlists yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Create your first playlist to save songs',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = _playlists[index];
                      final isSelected = _playlistStates[playlist.id] ?? false;
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _playlistStates[playlist.id] = !isSelected;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                // Playlist artwork
                                _buildPlaylistArtwork(playlist),
                                SizedBox(width: 16),
                                
                                // Playlist info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        playlist.name,
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Checkbox
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                        ? AppColors.primary 
                                        : AppColors.textSecondary.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                  child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Temporary fake record class to bridge the gap between Playlist and RecordModel
class _FakeRecord {
  final String id;
  final Map<String, dynamic> data;
  
  _FakeRecord({required this.id, required this.data});
}

// Helper function to show the modal
Future<void> showPlaylistSelectionModal(
  BuildContext context,
  Song song, {
  VoidCallback? onPlaylistsChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PlaylistSelectionModal(
      song: song,
      onPlaylistsChanged: onPlaylistsChanged,
    ),
  );
} 

