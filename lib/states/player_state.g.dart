// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerStateImpl _$$PlayerStateImplFromJson(Map<String, dynamic> json) =>
    _$PlayerStateImpl(
      currentSong: json['currentSong'] == null
          ? null
          : Song.fromJson(json['currentSong'] as Map<String, dynamic>),
      queue: (json['queue'] as List<dynamic>?)
              ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      currentPosition: json['currentPosition'] == null
          ? Duration.zero
          : Duration(microseconds: (json['currentPosition'] as num).toInt()),
      isPlaying: json['isPlaying'] as bool? ?? false,
      isBuffering: json['isBuffering'] as bool? ?? false,
      shuffleMode: json['shuffleMode'] as bool? ?? false,
      repeatMode:
          $enumDecodeNullable(_$RepeatModeEnumMap, json['repeatMode']) ??
              RepeatMode.off,
      currentPlaylistId: json['currentPlaylistId'] as String?,
    );

Map<String, dynamic> _$$PlayerStateImplToJson(_$PlayerStateImpl instance) =>
    <String, dynamic>{
      'currentSong': instance.currentSong,
      'queue': instance.queue,
      'currentIndex': instance.currentIndex,
      'currentPosition': instance.currentPosition.inMicroseconds,
      'isPlaying': instance.isPlaying,
      'isBuffering': instance.isBuffering,
      'shuffleMode': instance.shuffleMode,
      'repeatMode': _$RepeatModeEnumMap[instance.repeatMode]!,
      'currentPlaylistId': instance.currentPlaylistId,
    };

const _$RepeatModeEnumMap = {
  RepeatMode.off: 'off',
  RepeatMode.all: 'all',
  RepeatMode.one: 'one',
};


