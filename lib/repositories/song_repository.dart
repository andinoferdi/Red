import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';

/// Repository for handling song-related data
class SongRepository {
  final PocketBaseService _pocketBaseService;
  
  // Simple cache for all songs
  static List<Song>? _allSongsCache;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  SongRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Fetch all songs with caching
  Future<List<Song>> getAllSongs() async {
    try {
      // Check cache first
      if (_allSongsCache != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _allSongsCache!;
        }
      }
      
      // Load from database with higher perPage to get all songs
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 500, // Increased from 100 to ensure we get all songs
        expand: 'artist_id,album_id',
        sort: 'title',
      );
      
      final songs = response.items.map((record) => Song.fromRecord(record)).toList();
      
      // Update cache
      _allSongsCache = songs;
      _cacheTimestamp = DateTime.now();
      
      return songs;
    } catch (e) {
      // If error and we have cache, return cache
      if (_allSongsCache != null) {
        return _allSongsCache!;
      }
      throw Exception('Failed to fetch songs: $e');
    }
  }
  
  /// Clear the cache (useful for refresh)
  static void clearCache() {
    _allSongsCache = null;
    _cacheTimestamp = null;
  }
  
  /// Get a specific song by ID from cache or database
  Future<Song?> getSongById(String songId) async {
    try {
      // Try to find in cached songs first
      final allSongs = await getAllSongs();
      final cachedSong = allSongs.where((song) => song.id == songId).firstOrNull;
      
      if (cachedSong != null) {
        return cachedSong;
      }
      
      // If not found in cache, load directly from database
      final record = await _pb.collection('songs').getOne(
        songId,
        expand: 'artist_id,album_id',
      );
      
      return Song.fromRecord(record);
    } catch (e) {
      return null;
    }
  }
  
  /// Fetch songs by artist ID
  Future<List<Song>> getSongsByArtist(String artistId) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'artist_id = "$artistId"',
        expand: 'artist_id,album_id',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by artist: $e');
    }
  }

  /// Fetch songs by artist name (for Jelajahi Artist feature)
  Future<List<Song>> getSongsByArtistName(String artistName, {String? excludeSongId}) async {
    try {

      
      // Get all songs and filter in memory (more reliable for complex queries)
      final allSongs = await getAllSongs();
      
      // Filter songs by artist name (case-insensitive)
      List<Song> artistSongs = allSongs.where((song) {
        return song.artist.toLowerCase() == artistName.toLowerCase();
      }).toList();
      

      
      // Exclude current playing song if provided
      if (excludeSongId != null) {
        artistSongs = artistSongs.where((song) => song.id != excludeSongId).toList();

      }
      
      // Limit to 20 songs for horizontal scroll
      if (artistSongs.length > 20) {
        artistSongs = artistSongs.take(20).toList();
      }
      
      return artistSongs;
    } catch (e) {

      throw Exception('Failed to fetch songs by artist name: $e');
    }
  }
  
  /// Fetch songs by album ID
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'album_id = "$albumId"',
        expand: 'artist_id,album_id',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by album: $e');
    }
  }
  
  /// Fetch songs by playlist ID
  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    try {
      final response = await _pb.collection('playlist_songs').getList(
        page: 1,
        perPage: 100,
        filter: 'playlist.id = "$playlistId"',
        expand: 'song,song.artist_id,song.album_id',
      );
      
      return response.items
          .map((record) {
            final songRecord = record.expand['song']?[0];
            if (songRecord != null) {
              return Song.fromRecord(songRecord);
            }
            return null;
          })
          .where((song) => song != null)
          .cast<Song>()
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by playlist: $e');
    }
  }
  
  /// Search songs
  Future<List<Song>> searchSongs(String query) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'title ~ "$query" || artist_id.name ~ "$query" || album_id.title ~ "$query"',
        expand: 'artist_id,album_id',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to search songs: $e');
    }
  }
}
