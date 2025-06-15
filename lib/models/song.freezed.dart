// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'song.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Song _$SongFromJson(Map<String, dynamic> json) {
  return _Song.fromJson(json);
}

/// @nodoc
mixin _$Song {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  String get albumArtUrl => throw _privateConstructorUsedError;
  int get durationInSeconds => throw _privateConstructorUsedError;
  String get albumName => throw _privateConstructorUsedError;
  String? get lyrics => throw _privateConstructorUsedError;
  String? get playlistId => throw _privateConstructorUsedError;
  String? get audioFileUrl => throw _privateConstructorUsedError;
  String? get audioFileName => throw _privateConstructorUsedError;

  /// Serializes this Song to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SongCopyWith<Song> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SongCopyWith<$Res> {
  factory $SongCopyWith(Song value, $Res Function(Song) then) =
      _$SongCopyWithImpl<$Res, Song>;
  @useResult
  $Res call(
      {String id,
      String title,
      String artist,
      String albumArtUrl,
      int durationInSeconds,
      String albumName,
      String? lyrics,
      String? playlistId,
      String? audioFileUrl,
      String? audioFileName});
}

/// @nodoc
class _$SongCopyWithImpl<$Res, $Val extends Song>
    implements $SongCopyWith<$Res> {
  _$SongCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? albumArtUrl = null,
    Object? durationInSeconds = null,
    Object? albumName = null,
    Object? lyrics = freezed,
    Object? playlistId = freezed,
    Object? audioFileUrl = freezed,
    Object? audioFileName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      albumArtUrl: null == albumArtUrl
          ? _value.albumArtUrl
          : albumArtUrl // ignore: cast_nullable_to_non_nullable
              as String,
      durationInSeconds: null == durationInSeconds
          ? _value.durationInSeconds
          : durationInSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: freezed == lyrics
          ? _value.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as String?,
      playlistId: freezed == playlistId
          ? _value.playlistId
          : playlistId // ignore: cast_nullable_to_non_nullable
              as String?,
      audioFileUrl: freezed == audioFileUrl
          ? _value.audioFileUrl
          : audioFileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioFileName: freezed == audioFileName
          ? _value.audioFileName
          : audioFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SongImplCopyWith<$Res> implements $SongCopyWith<$Res> {
  factory _$$SongImplCopyWith(
          _$SongImpl value, $Res Function(_$SongImpl) then) =
      __$$SongImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String artist,
      String albumArtUrl,
      int durationInSeconds,
      String albumName,
      String? lyrics,
      String? playlistId,
      String? audioFileUrl,
      String? audioFileName});
}

/// @nodoc
class __$$SongImplCopyWithImpl<$Res>
    extends _$SongCopyWithImpl<$Res, _$SongImpl>
    implements _$$SongImplCopyWith<$Res> {
  __$$SongImplCopyWithImpl(_$SongImpl _value, $Res Function(_$SongImpl) _then)
      : super(_value, _then);

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? artist = null,
    Object? albumArtUrl = null,
    Object? durationInSeconds = null,
    Object? albumName = null,
    Object? lyrics = freezed,
    Object? playlistId = freezed,
    Object? audioFileUrl = freezed,
    Object? audioFileName = freezed,
  }) {
    return _then(_$SongImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      artist: null == artist
          ? _value.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String,
      albumArtUrl: null == albumArtUrl
          ? _value.albumArtUrl
          : albumArtUrl // ignore: cast_nullable_to_non_nullable
              as String,
      durationInSeconds: null == durationInSeconds
          ? _value.durationInSeconds
          : durationInSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      albumName: null == albumName
          ? _value.albumName
          : albumName // ignore: cast_nullable_to_non_nullable
              as String,
      lyrics: freezed == lyrics
          ? _value.lyrics
          : lyrics // ignore: cast_nullable_to_non_nullable
              as String?,
      playlistId: freezed == playlistId
          ? _value.playlistId
          : playlistId // ignore: cast_nullable_to_non_nullable
              as String?,
      audioFileUrl: freezed == audioFileUrl
          ? _value.audioFileUrl
          : audioFileUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      audioFileName: freezed == audioFileName
          ? _value.audioFileName
          : audioFileName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SongImpl with DiagnosticableTreeMixin implements _Song {
  const _$SongImpl(
      {required this.id,
      required this.title,
      required this.artist,
      required this.albumArtUrl,
      required this.durationInSeconds,
      required this.albumName,
      this.lyrics,
      this.playlistId,
      this.audioFileUrl,
      this.audioFileName});

  factory _$SongImpl.fromJson(Map<String, dynamic> json) =>
      _$$SongImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String artist;
  @override
  final String albumArtUrl;
  @override
  final int durationInSeconds;
  @override
  final String albumName;
  @override
  final String? lyrics;
  @override
  final String? playlistId;
  @override
  final String? audioFileUrl;
  @override
  final String? audioFileName;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Song(id: $id, title: $title, artist: $artist, albumArtUrl: $albumArtUrl, durationInSeconds: $durationInSeconds, albumName: $albumName, lyrics: $lyrics, playlistId: $playlistId, audioFileUrl: $audioFileUrl, audioFileName: $audioFileName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Song'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('artist', artist))
      ..add(DiagnosticsProperty('albumArtUrl', albumArtUrl))
      ..add(DiagnosticsProperty('durationInSeconds', durationInSeconds))
      ..add(DiagnosticsProperty('albumName', albumName))
      ..add(DiagnosticsProperty('lyrics', lyrics))
      ..add(DiagnosticsProperty('playlistId', playlistId))
      ..add(DiagnosticsProperty('audioFileUrl', audioFileUrl))
      ..add(DiagnosticsProperty('audioFileName', audioFileName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SongImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.albumArtUrl, albumArtUrl) ||
                other.albumArtUrl == albumArtUrl) &&
            (identical(other.durationInSeconds, durationInSeconds) ||
                other.durationInSeconds == durationInSeconds) &&
            (identical(other.albumName, albumName) ||
                other.albumName == albumName) &&
            (identical(other.lyrics, lyrics) || other.lyrics == lyrics) &&
            (identical(other.playlistId, playlistId) ||
                other.playlistId == playlistId) &&
            (identical(other.audioFileUrl, audioFileUrl) ||
                other.audioFileUrl == audioFileUrl) &&
            (identical(other.audioFileName, audioFileName) ||
                other.audioFileName == audioFileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      artist,
      albumArtUrl,
      durationInSeconds,
      albumName,
      lyrics,
      playlistId,
      audioFileUrl,
      audioFileName);

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      __$$SongImplCopyWithImpl<_$SongImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SongImplToJson(
      this,
    );
  }
}

abstract class _Song implements Song {
  const factory _Song(
      {required final String id,
      required final String title,
      required final String artist,
      required final String albumArtUrl,
      required final int durationInSeconds,
      required final String albumName,
      final String? lyrics,
      final String? playlistId,
      final String? audioFileUrl,
      final String? audioFileName}) = _$SongImpl;

  factory _Song.fromJson(Map<String, dynamic> json) = _$SongImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get artist;
  @override
  String get albumArtUrl;
  @override
  int get durationInSeconds;
  @override
  String get albumName;
  @override
  String? get lyrics;
  @override
  String? get playlistId;
  @override
  String? get audioFileUrl;
  @override
  String? get audioFileName;

  /// Create a copy of Song
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SongImplCopyWith<_$SongImpl> get copyWith =>
      throw _privateConstructorUsedError;
}


