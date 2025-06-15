import 'package:pocketbase/pocketbase.dart';
import '../../models/play_history.dart';

class PlayHistoryRepository {
  final PocketBase pb;

  PlayHistoryRepository(this.pb);

  Future<List<PlayHistory>> getRecentlyPlayed(String userId, {int limit = 5}) async {
    try {
      if (userId.isEmpty) {
        return [];
      }
      
      final result = await pb.collection('user_history').getList(
        page: 1,
        perPage: limit,
        filter: 'user_id = "$userId"',
        sort: '-played_at',
      );
      
      if (result.items.isEmpty) {
        return [];
      }
      
      final List<PlayHistory> histories = [];
      
      // Process each history record
      for (final record in result.items) {
        try {
          final songId = record.data['song_id'] as String? ?? '';
          
          // Get song data directly without using expand
          RecordModel? songRecord;
          RecordModel? artistRecord;
          RecordModel? albumRecord;
          
          if (songId.isNotEmpty) {
            try {
              songRecord = await pb.collection('songs').getOne(songId);
              
              // Get artist if available
              final artistId = songRecord.data['artist_id'] as String?;
              if (artistId != null && artistId.isNotEmpty) {
                try {
                  artistRecord = await pb.collection('artists').getOne(artistId);
                } catch (e) {
                  // Silently handle artist fetch error
                }
              }
              
              // Get album if available
              final albumId = songRecord.data['album_id'] as String?;
              if (albumId != null && albumId.isNotEmpty) {
                try {
                  albumRecord = await pb.collection('albums').getOne(albumId);
                } catch (e) {
                  // Silently handle album fetch error
                }
              }
            } catch (e) {
              // Silently handle song fetch error
            }
          }
          
          // Create PlayHistory object
          final history = PlayHistory.fromRecord(
            record,
            songRecord: songRecord,
            artistRecord: artistRecord,
            albumRecord: albumRecord,
            baseUrl: pb.baseUrl,
          );
          
          histories.add(history);
        } catch (e) {
          // Skip this record on error
        }
      }

      return histories;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<void> addPlayHistory({
    required String userId, 
    required String songId,
    int? durationSeconds,
    bool completed = false,
  }) async {
    try {
      // First, delete any existing history for this song to avoid duplicates
      final existingHistory = await pb.collection('user_history').getList(
        page: 1,
        perPage: 50, // Get more records to ensure we find all duplicates
        filter: 'user_id = "$userId" && song_id = "$songId"',
      );
      
      // Delete all existing records for this song
      for (final record in existingHistory.items) {
        try {
          await pb.collection('user_history').delete(record.id);
        } catch (e) {
          // Continue if delete fails
        }
      }
      
      // Now create a new record
      await pb.collection('user_history').create(body: {
        'user_id': userId,
        'song_id': songId,
        'play_duration_seconds': durationSeconds,
        'completed': completed,
        'played_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
