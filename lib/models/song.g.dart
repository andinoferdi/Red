// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SongImpl _$$SongImplFromJson(Map<String, dynamic> json) => _$SongImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      albumArtUrl: json['albumArtUrl'] as String,
      durationInSeconds: (json['durationInSeconds'] as num).toInt(),
      albumName: json['albumName'] as String,
      lyrics: json['lyrics'] as String?,
      playlistId: json['playlistId'] as String?,
      audioFileUrl: json['audioFileUrl'] as String?,
      audioFileName: json['audioFileName'] as String?,
    );

Map<String, dynamic> _$$SongImplToJson(_$SongImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'albumArtUrl': instance.albumArtUrl,
      'durationInSeconds': instance.durationInSeconds,
      'albumName': instance.albumName,
      'lyrics': instance.lyrics,
      'playlistId': instance.playlistId,
      'audioFileUrl': instance.audioFileUrl,
      'audioFileName': instance.audioFileName,
    };


