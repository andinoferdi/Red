import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';
import '../models/playlist.dart';

/// Repository for handling song-playlist relationships
class SongPlaylistRepository {
  final PocketBaseService _pbService;
  
  SongPlaylistRepository(this._pbService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pbService.pb;
  
  /// Get songs in a playlist
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    try {
      // Get song_playlist relationships with full song, artist, and album data
      final songPlaylistResult = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId"',
        expand: 'song_id,song_id.artist_id,song_id.album_id',
        sort: 'order', // Sort by order field properly
        perPage: 500, // Make sure we get all songs
      );
      
      final List<MapEntry<Song, int>> songsWithOrder = [];
      
      for (final record in songPlaylistResult.items) {
        final songData = record.expand['song_id'];
        if (songData != null && songData.isNotEmpty) {
          final songRecord = songData.first;
          final song = Song.fromRecord(songRecord);
          final order = record.data['order'] as int?;
          
          // Use order if available, otherwise use created timestamp as fallback
          final finalOrder = order ?? DateTime.parse(record.created).millisecondsSinceEpoch;
          songsWithOrder.add(MapEntry(song, finalOrder));
        }
      }
      
      // Sort by order (ascending)
      songsWithOrder.sort((a, b) => a.value.compareTo(b.value));
      
      // Extract songs from sorted list
      final List<Song> songs = songsWithOrder.map((entry) => entry.key).toList();
      
      return songs;
    } catch (e) {
      debugPrint('Get playlist songs error: $e');
      throw Exception('Failed to fetch playlist songs: $e');
    }
  }
  
  /// Get playlists containing a specific song
  Future<List<Playlist>> getPlaylistsContainingSong(String songId) async {
    try {
      
      // Use song_playlists collection to find playlists containing the song
      final songPlaylistRecords = await _pb.collection('song_playlists').getList(
        filter: 'song_id = "$songId"',
        expand: 'playlist_id',
      );
      
      final List<Playlist> playlists = [];
      final Set<String> playlistIds = {};
      
      for (final record in songPlaylistRecords.items) {
        final playlistId = record.data['playlist_id'] as String?;
        if (playlistId != null && !playlistIds.contains(playlistId)) {
          playlistIds.add(playlistId);
          
          try {
            // Get the full playlist record
            final playlistRecord = await _pb.collection('playlists').getOne(playlistId);
            final playlist = Playlist.fromRecord(playlistRecord);
            
            // Get all songs for this playlist using song_playlists
            final playlistSongs = await getPlaylistSongs(playlistId);
            final songIds = playlistSongs.map((song) => song.id).toList();
            
            // Create playlist with correct songs list
            final playlistWithSongs = Playlist(
              id: playlist.id,
              name: playlist.name,
              userId: playlist.userId,
              songs: songIds,
              imageUrl: playlist.imageUrl,
              createdAt: playlist.createdAt,
              updatedAt: playlist.updatedAt,
            );
            
            playlists.add(playlistWithSongs);

                      } catch (e) {
              continue;
            }
        }
      }
      
              
        return playlists;
      } catch (e) {
      throw Exception('Failed to get playlists containing song: $e');
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    try {
      
      final records = await _pb.collection('playlists').getList();
      
      final List<Playlist> playlists = [];
      
      for (final record in records.items) {
        try {
          
          final playlist = Playlist.fromRecord(record);
          
          // Get songs for this playlist using song_playlists collection
          final playlistSongs = await getPlaylistSongs(playlist.id);
          final songIds = playlistSongs.map((song) => song.id).toList();
          
          // Create playlist with correct songs list
          final playlistWithSongs = Playlist(
            id: playlist.id,
            name: playlist.name,
            userId: playlist.userId,
            songs: songIds,
            imageUrl: playlist.imageUrl,
            createdAt: playlist.createdAt,
            updatedAt: playlist.updatedAt,
          );
          
          playlists.add(playlistWithSongs);
        } catch (e) {
          continue;
        }
      }
      
      
      return playlists;
    } catch (e) {
      throw Exception('Failed to get all playlists: $e');
    }
  }

  /// Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      
      // Check if relationship already exists
      final existingRecords = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (existingRecords.items.isEmpty) {
        // Get the highest order value in this playlist to determine the next position
        int nextOrder = 1; // Default for empty playlist
        
        try {
          final playlistSongs = await _pb.collection('song_playlists').getList(
            filter: 'playlist_id = "$playlistId"',
            sort: '-order', // Sort by order descending to get highest first
            perPage: 1, // Only need the first (highest) record
          );
          
          if (playlistSongs.items.isNotEmpty) {
            final highestOrder = playlistSongs.items.first.data['order'] as int?;
            nextOrder = (highestOrder ?? 0) + 1;
          }
        } catch (e) {
          // Continue with nextOrder = 1 as fallback
        }
        
        // Create new song_playlist relationship with proper order
        await _pb.collection('song_playlists').create(body: {
          'playlist_id': playlistId,
          'song_id': songId,
          'order': nextOrder,
        });
      } else {
      }
    } catch (e) {
      throw Exception('Failed to add song to playlist: $e');
    }
  }
  
  /// Add multiple songs to playlist with proper ordering
  Future<void> addMultipleSongsToPlaylist(String playlistId, List<String> songIds) async {
    if (songIds.isEmpty) return;
    
    try {
      
      // Get the highest order value in this playlist
      int nextOrder = 1; // Default for empty playlist
      
      try {
        final playlistSongs = await _pb.collection('song_playlists').getList(
          filter: 'playlist_id = "$playlistId"',
          sort: '-order', // Sort by order descending to get highest first
          perPage: 1, // Only need the first (highest) record
        );
        
        if (playlistSongs.items.isNotEmpty) {
          final highestOrder = playlistSongs.items.first.data['order'] as int?;
          nextOrder = (highestOrder ?? 0) + 1;
        }
      } catch (e) {
        // Continue with nextOrder = 1 as fallback
      }
      
      // Add each song with incremental order
      for (int i = 0; i < songIds.length; i++) {
        final songId = songIds[i];
        
        // Check if relationship already exists
        final existingRecords = await _pb.collection('song_playlists').getList(
          filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
        );
        
        if (existingRecords.items.isEmpty) {
          await _pb.collection('song_playlists').create(body: {
            'playlist_id': playlistId,
            'song_id': songId,
            'order': nextOrder + i,
          });
        } else {
        }
      }
      
    } catch (e) {
      throw Exception('Failed to add multiple songs to playlist: $e');
    }
  }
  
  /// Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      
      // Find and delete the song_playlist relationship
      final records = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      for (final record in records.items) {
        await _pb.collection('song_playlists').delete(record.id);
      }
      
    } catch (e) {
      throw Exception('Failed to remove song from playlist: $e');
    }
  }

  /// Update song order in playlist
  Future<void> updateSongOrder(String playlistId, String songId, int order) async {
    try {
      final result = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (result.items.isNotEmpty) {
        await _pb.collection('song_playlists').update(result.items.first.id, body: {
          'order': order,
        });
      }
    } catch (e) {
      debugPrint('Update song order error: $e');
      throw Exception('Failed to update song order: $e');
    }
  }
  
  Future<Playlist> createPlaylist(String name, String userId) async {
    try {
      final record = await _pb.collection('playlists').create(
        body: {
          'name': name,
          'user': userId,
          'songs': [],
        },
      );
      return Playlist.fromRecord(record);
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }
}
