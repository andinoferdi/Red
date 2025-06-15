// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaylistStateImpl _$$PlaylistStateImplFromJson(Map<String, dynamic> json) =>
    _$PlaylistStateImpl(
      playlists: (json['playlists'] as List<dynamic>?)
              ?.map((e) => Playlist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentPlaylist: json['currentPlaylist'] == null
          ? null
          : Playlist.fromJson(json['currentPlaylist'] as Map<String, dynamic>),
      currentSong: json['currentSong'] == null
          ? null
          : Song.fromJson(json['currentSong'] as Map<String, dynamic>),
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$PlaylistStateImplToJson(_$PlaylistStateImpl instance) =>
    <String, dynamic>{
      'playlists': instance.playlists,
      'currentPlaylist': instance.currentPlaylist,
      'currentSong': instance.currentSong,
      'isLoading': instance.isLoading,
      'error': instance.error,
    };
