// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlaylistState _$PlaylistStateFromJson(Map<String, dynamic> json) {
  return _PlaylistState.fromJson(json);
}

/// @nodoc
mixin _$PlaylistState {
  List<Playlist> get playlists => throw _privateConstructorUsedError;
  Playlist? get currentPlaylist => throw _privateConstructorUsedError;
  Song? get currentSong => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Serializes this PlaylistState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaylistStateCopyWith<PlaylistState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistStateCopyWith<$Res> {
  factory $PlaylistStateCopyWith(
          PlaylistState value, $Res Function(PlaylistState) then) =
      _$PlaylistStateCopyWithImpl<$Res, PlaylistState>;
  @useResult
  $Res call(
      {List<Playlist> playlists,
      Playlist? currentPlaylist,
      Song? currentSong,
      bool isLoading,
      String? error});

  $PlaylistCopyWith<$Res>? get currentPlaylist;
  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class _$PlaylistStateCopyWithImpl<$Res, $Val extends PlaylistState>
    implements $PlaylistStateCopyWith<$Res> {
  _$PlaylistStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playlists = null,
    Object? currentPlaylist = freezed,
    Object? currentSong = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      playlists: null == playlists
          ? _value.playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<Playlist>,
      currentPlaylist: freezed == currentPlaylist
          ? _value.currentPlaylist
          : currentPlaylist // ignore: cast_nullable_to_non_nullable
              as Playlist?,
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res>? get currentPlaylist {
    if (_value.currentPlaylist == null) {
      return null;
    }

    return $PlaylistCopyWith<$Res>(_value.currentPlaylist!, (value) {
      return _then(_value.copyWith(currentPlaylist: value) as $Val);
    });
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SongCopyWith<$Res>? get currentSong {
    if (_value.currentSong == null) {
      return null;
    }

    return $SongCopyWith<$Res>(_value.currentSong!, (value) {
      return _then(_value.copyWith(currentSong: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlaylistStateImplCopyWith<$Res>
    implements $PlaylistStateCopyWith<$Res> {
  factory _$$PlaylistStateImplCopyWith(
          _$PlaylistStateImpl value, $Res Function(_$PlaylistStateImpl) then) =
      __$$PlaylistStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Playlist> playlists,
      Playlist? currentPlaylist,
      Song? currentSong,
      bool isLoading,
      String? error});

  @override
  $PlaylistCopyWith<$Res>? get currentPlaylist;
  @override
  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class __$$PlaylistStateImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateImpl>
    implements _$$PlaylistStateImplCopyWith<$Res> {
  __$$PlaylistStateImplCopyWithImpl(
      _$PlaylistStateImpl _value, $Res Function(_$PlaylistStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playlists = null,
    Object? currentPlaylist = freezed,
    Object? currentSong = freezed,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$PlaylistStateImpl(
      playlists: null == playlists
          ? _value._playlists
          : playlists // ignore: cast_nullable_to_non_nullable
              as List<Playlist>,
      currentPlaylist: freezed == currentPlaylist
          ? _value.currentPlaylist
          : currentPlaylist // ignore: cast_nullable_to_non_nullable
              as Playlist?,
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaylistStateImpl implements _PlaylistState {
  const _$PlaylistStateImpl(
      {final List<Playlist> playlists = const [],
      this.currentPlaylist,
      this.currentSong,
      this.isLoading = false,
      this.error})
      : _playlists = playlists;

  factory _$PlaylistStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaylistStateImplFromJson(json);

  final List<Playlist> _playlists;
  @override
  @JsonKey()
  List<Playlist> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  @override
  final Playlist? currentPlaylist;
  @override
  final Song? currentSong;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'PlaylistState(playlists: $playlists, currentPlaylist: $currentPlaylist, currentSong: $currentSong, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateImpl &&
            const DeepCollectionEquality()
                .equals(other._playlists, _playlists) &&
            (identical(other.currentPlaylist, currentPlaylist) ||
                other.currentPlaylist == currentPlaylist) &&
            (identical(other.currentSong, currentSong) ||
                other.currentSong == currentSong) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_playlists),
      currentPlaylist,
      currentSong,
      isLoading,
      error);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistStateImplCopyWith<_$PlaylistStateImpl> get copyWith =>
      __$$PlaylistStateImplCopyWithImpl<_$PlaylistStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaylistStateImplToJson(
      this,
    );
  }
}

abstract class _PlaylistState implements PlaylistState {
  const factory _PlaylistState(
      {final List<Playlist> playlists,
      final Playlist? currentPlaylist,
      final Song? currentSong,
      final bool isLoading,
      final String? error}) = _$PlaylistStateImpl;

  factory _PlaylistState.fromJson(Map<String, dynamic> json) =
      _$PlaylistStateImpl.fromJson;

  @override
  List<Playlist> get playlists;
  @override
  Playlist? get currentPlaylist;
  @override
  Song? get currentSong;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistStateImplCopyWith<_$PlaylistStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}


