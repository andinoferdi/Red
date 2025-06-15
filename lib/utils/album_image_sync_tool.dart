import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

/// Tool untuk membantu sync album images yang sudah diupload ulang
class AlbumImageSyncTool {
  final PocketBaseService _pbService;
  
  AlbumImageSyncTool(this._pbService);
  
  /// Cek semua album dan tampilkan status cover image
  Future<void> checkAllAlbumImages() async {
    try {
      await _pbService.initialize();
      
      // Get semua album
      final albums = await _pbService.pb.collection('albums').getList(
        perPage: 100,
      );
      
      debugPrint('🔍 Checking ${albums.items.length} albums...');
      
      for (final album in albums.items) {
        await _checkAlbumImage(album);
      }
      
      debugPrint('✅ Album image check completed');
    } catch (e) {
      debugPrint('❌ Error checking album images: $e');
    }
  }
  
  /// Cek satu album dan tampilkan status cover image
  Future<void> _checkAlbumImage(RecordModel album) async {
    final albumName = album.data['name'] ?? album.data['title'] ?? 'Unknown';
    final coverImage = album.data['cover_image'] as String?;
    
    debugPrint('📀 Album: $albumName (ID: ${album.id})');
    
    if (coverImage == null || coverImage.isEmpty) {
      debugPrint('   ⚠️  No cover image set');
      return;
    }
    
    // Generate URL dan cek apakah file ada
    final imageUrl = '${_pbService.pb.baseUrl}/api/files/${album.collectionId}/${album.id}/$coverImage';
    debugPrint('   🖼️  Cover image: $coverImage');
    debugPrint('   🔗 URL: $imageUrl');
    
    // Cek apakah file benar-benar ada dengan melakukan HEAD request
    try {
      final response = await _pbService.pb.send('/api/files/${album.collectionId}/${album.id}/$coverImage', 
        method: 'HEAD');
      
      if (response.statusCode == 200) {
        debugPrint('   ✅ Image file exists');
      } else {
        debugPrint('   ❌ Image file NOT found (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('   ❌ Image file NOT found (Error: $e)');
    }
    
    debugPrint('');
  }
  
  /// List semua file yang ada di album record untuk membantu identifikasi nama file yang benar
  Future<void> listAlbumFiles(String albumId) async {
    try {
      await _pbService.initialize();
      
      // Get album record
      final album = await _pbService.pb.collection('albums').getOne(albumId);
      
      debugPrint('📀 Album: ${album.data['name'] ?? album.data['title']} (ID: $albumId)');
      debugPrint('🗂️  Files in this album record:');
      
      // List semua field yang mungkin berisi file
      album.data.forEach((key, value) {
        if (value is String && value.isNotEmpty && value.contains('.')) {
          debugPrint('   📄 $key: $value');
        }
      });
      
      // Coba akses folder file album untuk melihat file apa saja yang ada
      try {
        final filesUrl = '${_pbService.pb.baseUrl}/api/files/${album.collectionId}/${album.id}/';
        debugPrint('🔗 Files folder URL: $filesUrl');
        debugPrint('💡 Tip: Buka URL ini di browser untuk melihat semua file yang ada');
      } catch (e) {
        debugPrint('⚠️  Cannot list files: $e');
      }
      
    } catch (e) {
      debugPrint('❌ Error getting album: $e');
    }
  }
  
  /// Update cover image untuk album tertentu
  Future<void> updateAlbumCoverImage(String albumId, String newCoverImageFileName) async {
    try {
      await _pbService.initialize();
      
      // Update album record
      await _pbService.pb.collection('albums').update(albumId, body: {
        'cover_image': newCoverImageFileName,
      });
      
      debugPrint('✅ Updated album $albumId cover image to: $newCoverImageFileName');
      
      // Verify the update
      final updatedAlbum = await _pbService.pb.collection('albums').getOne(albumId);
      final newCoverImage = updatedAlbum.data['cover_image'];
      debugPrint('🔍 Verified: cover_image is now: $newCoverImage');
      
    } catch (e) {
      debugPrint('❌ Error updating album cover image: $e');
    }
  }
} 

