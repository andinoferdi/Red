import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../services/pocketbase_service.dart';

/// Repository for handling playlist-related data
class PlaylistRepository {
  final PocketBaseService _pocketBaseService;
  
  PlaylistRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Get user playlists
  Future<List<RecordModel>> getUserPlaylists() async {
    try {
      final result = await _pb.collection('playlists').getList(
        filter: 'user_id = "${_pocketBaseService.currentUser?.id}"',
        sort: '-updated',
      );
      return result.items;
    } catch (e) {
      throw Exception('Failed to fetch playlists: $e');
    }
  }
  
  /// Create a new playlist
  Future<RecordModel> createPlaylist({
    required String name,
    String? description,
    required bool isPublic,
    File? coverImageFile,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description ?? '',
        'is_public': isPublic,
        'user_id': _pocketBaseService.currentUser?.id,
      };
      
      // If cover image is provided, add it to the form data
      final List<http.MultipartFile> files = [];
      if (coverImageFile != null) {
        files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImageFile.path,
        ));
      }
      
      return await _pb.collection('playlists').create(
        body: body,
        files: files,
      );
    } catch (e) {
      debugPrint('Create playlist error: $e');
      throw Exception('Failed to create playlist: $e');
    }
  }
  
  /// Update an existing playlist
  Future<RecordModel> updatePlaylist({
    required String playlistId,
    required String name,
    String? description,
    required bool isPublic,
    File? coverImageFile,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description ?? '',
        'is_public': isPublic,
      };
      
      // If cover image is provided, add it to the form data
      final List<http.MultipartFile> files = [];
      if (coverImageFile != null) {
        files.add(await http.MultipartFile.fromPath(
          'cover_image',
          coverImageFile.path,
        ));
      }
      
      return await _pb.collection('playlists').update(
        playlistId,
        body: body,
        files: files,
      );
    } catch (e) {
      debugPrint('Update playlist error: $e');
      throw Exception('Failed to update playlist: $e');
    }
  }
  
  /// Delete a playlist and all its song relationships
  Future<void> deletePlaylist(String playlistId) async {
    try {
      // First, delete all song_playlist relationships for this playlist
      final songPlaylistRecords = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId"',
        perPage: 500, // Get all records
      );
      
      // Delete each song_playlist record
      for (final record in songPlaylistRecords.items) {
        await _pb.collection('song_playlists').delete(record.id);
      }
      
      debugPrint('Deleted ${songPlaylistRecords.items.length} song_playlist records for playlist $playlistId');
      
      // Then delete the playlist itself
      await _pb.collection('playlists').delete(playlistId);
      
      debugPrint('Successfully deleted playlist $playlistId');
    } catch (e) {
      debugPrint('Delete playlist error: $e');
      throw Exception('Failed to delete playlist: $e');
    }
  }
  
  /// Get cover image URL for a playlist
  String getCoverImageUrl(RecordModel playlist) {
    final coverImage = playlist.data['cover_image'] as String?;
    if (coverImage != null && coverImage.trim().isNotEmpty) {
      try {
        final url = _pb.files.getUrl(playlist, coverImage).toString();
        debugPrint('🖼️ Generated playlist cover URL: $url');
        return url;
      } catch (e) {
        debugPrint('⚠️ Error generating playlist cover URL: $e');
        return '';
      }
    }
    return '';
  }
}
