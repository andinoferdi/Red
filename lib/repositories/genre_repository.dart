import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/genre_model.dart';

/// Repository for handling genre-related data
class GenreRepository {
  final PocketBaseService _pocketBaseService;
  
  GenreRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Get all genres
  Future<List<GenreModel>> getGenres() async {
    try {
      final response = await _pb.collection('genres').getList(
        page: 1,
        perPage: 50,
      );
      
      // Get the base URL for constructing file URLs
      final baseUrl = _pb.baseUrl;
      
      return response.items.map((record) => 
        GenreModel.fromRecord(record, baseUrl: baseUrl)
      ).toList();
    } catch (e) {
      // Improve error handling with specific error messages
      if (e.toString().contains('Failed to connect') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Network error. Please check your connection');
      }
      
      throw Exception('Failed to load genres: ${e.toString()}');
    }
  }
}
