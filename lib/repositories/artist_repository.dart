import 'package:flutter/foundation.dart';
import '../models/artist.dart';
import '../services/pocketbase_service.dart';

class ArtistRepository {
  final PocketBaseService _pocketBaseService;

  ArtistRepository(this._pocketBaseService);

  /// Get artist by name
  Future<Artist?> getArtistByName(String artistName) async {
    try {
      final pb = _pocketBaseService.pb;
      
      // Search for artist by name (case-insensitive)
      final records = await pb.collection('artists').getList(
        page: 1,
        perPage: 1,
        filter: 'name ~ "$artistName"',
      );

      if (records.items.isNotEmpty) {
        return Artist.fromRecord(records.items.first, pb);
      }
      
      return null;
    } catch (e) {

      return null;
    }
  }

  /// Get artist by ID
  Future<Artist?> getArtistById(String artistId) async {
    try {
      final pb = _pocketBaseService.pb;
      final record = await pb.collection('artists').getOne(artistId);
      return Artist.fromRecord(record, pb);
    } catch (e) {

      return null;
    }
  }

  /// Get all artists
  Future<List<Artist>> getAllArtists() async {
    try {
      final pb = _pocketBaseService.pb;
      final records = await pb.collection('artists').getFullList();
      
      return records.map((record) => Artist.fromRecord(record, pb)).toList();
    } catch (e) {

      return [];
    }
  }

  /// Search artists by name
  Future<List<Artist>> searchArtists(String query) async {
    try {
      final pb = _pocketBaseService.pb;
      final records = await pb.collection('artists').getList(
        page: 1,
        perPage: 50,
        filter: 'name ~ "$query"',
        sort: 'name',
      );
      
      return records.items.map((record) => Artist.fromRecord(record, pb)).toList();
    } catch (e) {

      return [];
    }
  }
} 

