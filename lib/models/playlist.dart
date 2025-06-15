import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required String userId,
    required List<String> songs,
    String? imageUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

  factory Playlist.fromRecord(RecordModel record) {
    // Try different possible field names for songs
    List<String> songs = [];
    if (record.data.containsKey('songs')) {
      songs = List<String>.from(record.data['songs'] ?? []);
    } else if (record.data.containsKey('song_ids')) {
      songs = List<String>.from(record.data['song_ids'] ?? []);
    } else if (record.data.containsKey('tracks')) {
      songs = List<String>.from(record.data['tracks'] ?? []);
    }
    // Note: Songs field parsing handles multiple possible field names
    
    return Playlist(
      id: record.id,
      name: record.data['name'] as String? ?? 'Untitled Playlist',
      userId: record.data['user'] as String? ?? record.data['user_id'] as String? ?? '',
      songs: songs,
      imageUrl: record.data['image_url'] as String? ?? record.data['cover_image'] as String?,
      createdAt: DateTime.parse(record.created),
      updatedAt: DateTime.parse(record.updated),
    );
  }
}


