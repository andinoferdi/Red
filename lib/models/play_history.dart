import 'package:pocketbase/pocketbase.dart';

class PlayHistory {
  final String id;
  final String userId;
  final String songId;
  final DateTime playedAt;
  final int? playDurationSeconds;
  final bool completed;

  // Tambahan field yang diambil dari relasi
  final String? songTitle;
  final String? artistName;
  final String? albumCoverUrl;

  PlayHistory({
    required this.id,
    required this.userId,
    required this.songId,
    required this.playedAt,
    this.playDurationSeconds,
    required this.completed,
    this.songTitle,
    this.artistName,
    this.albumCoverUrl,
  });

  factory PlayHistory.fromRecord(RecordModel record, {
    RecordModel? songRecord,
    RecordModel? artistRecord,
    RecordModel? albumRecord,
    required String baseUrl,
  }) {
    // Ekstrak data dasar dari record history
    final id = record.id;
    
    // Handle berbagai format user_id yang mungkin (string atau relation)
    String userId = '';
    final userIdRaw = record.data['user_id'];
    if (userIdRaw is String) {
      userId = userIdRaw;
    } else if (userIdRaw is Map) {
      // Handle case where user_id might be an expanded relation object
      userId = userIdRaw['id'] as String? ?? '';
    }
    
    // Handle berbagai format song_id
    String songId = '';
    final songIdRaw = record.data['song_id'];
    if (songIdRaw is String) {
      songId = songIdRaw;
    } else if (songIdRaw is Map) {
      songId = songIdRaw['id'] as String? ?? '';
    }
    
    final playedAtStr = record.data['played_at'] as String? ?? DateTime.now().toIso8601String();
    final playedAt = DateTime.parse(playedAtStr);
    final playDurationSeconds = record.data['play_duration_seconds'] as int?;
    final completed = record.data['completed'] as bool? ?? false;

    // Ekstrak data dari relasi song jika tersedia
    String? songTitle;
    String? artistName;
    String? albumCoverUrl;

    if (songRecord != null) {
      try {
        songTitle = songRecord.data['title'] as String?;
      } catch (e) {
        // Silently handle error
      }
      
      if (artistRecord != null) {
        try {
          artistName = artistRecord.data['name'] as String?;
        } catch (e) {
          // Silently handle error
        }
      } else if (songRecord.data['artist_name'] != null) {
        // Fallback to artist_name field if directly in song record
        artistName = songRecord.data['artist_name'] as String?;
      }
      
      if (albumRecord != null && albumRecord.data['cover_image'] != null) {
        try {
          final coverImage = albumRecord.data['cover_image'];
          albumCoverUrl = '$baseUrl/api/files/${albumRecord.collectionId}/${albumRecord.id}/$coverImage';
        } catch (e) {
          // Silently handle error
        }
      } else if (songRecord.data['album_cover'] != null) {
        // Fallback to direct album_cover field
        try {
          final coverImage = songRecord.data['album_cover'];
          albumCoverUrl = '$baseUrl/api/files/${songRecord.collectionId}/${songRecord.id}/$coverImage';
        } catch (e) {
          // Silently handle error
        }
      }
    }

    return PlayHistory(
      id: id,
      userId: userId,
      songId: songId,
      playedAt: playedAt,
      playDurationSeconds: playDurationSeconds,
      completed: completed,
      songTitle: songTitle ?? 'Unknown Song',
      artistName: artistName ?? 'Unknown Artist',
      albumCoverUrl: albumCoverUrl,
    );
  }
}


