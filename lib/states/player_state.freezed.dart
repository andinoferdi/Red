// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) {
  return _PlayerState.fromJson(json);
}

/// @nodoc
mixin _$PlayerState {
  Song? get currentSong => throw _privateConstructorUsedError;
  List<Song> get queue => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  Duration get currentPosition => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  bool get isBuffering => throw _privateConstructorUsedError;
  bool get shuffleMode => throw _privateConstructorUsedError;
  RepeatMode get repeatMode => throw _privateConstructorUsedError;
  String? get currentPlaylistId => throw _privateConstructorUsedError;

  /// Serializes this PlayerState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
          PlayerState value, $Res Function(PlayerState) then) =
      _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call(
      {Song? currentSong,
      List<Song> queue,
      int currentIndex,
      Duration currentPosition,
      bool isPlaying,
      bool isBuffering,
      bool shuffleMode,
      RepeatMode repeatMode,
      String? currentPlaylistId});

  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? queue = null,
    Object? currentIndex = null,
    Object? currentPosition = null,
    Object? isPlaying = null,
    Object? isBuffering = null,
    Object? shuffleMode = null,
    Object? repeatMode = null,
    Object? currentPlaylistId = freezed,
  }) {
    return _then(_value.copyWith(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      queue: null == queue
          ? _value.queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<Song>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isBuffering: null == isBuffering
          ? _value.isBuffering
          : isBuffering // ignore: cast_nullable_to_non_nullable
              as bool,
      shuffleMode: null == shuffleMode
          ? _value.shuffleMode
          : shuffleMode // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as RepeatMode,
      currentPlaylistId: freezed == currentPlaylistId
          ? _value.currentPlaylistId
          : currentPlaylistId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of PlayerState
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
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
          _$PlayerStateImpl value, $Res Function(_$PlayerStateImpl) then) =
      __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Song? currentSong,
      List<Song> queue,
      int currentIndex,
      Duration currentPosition,
      bool isPlaying,
      bool isBuffering,
      bool shuffleMode,
      RepeatMode repeatMode,
      String? currentPlaylistId});

  @override
  $SongCopyWith<$Res>? get currentSong;
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
      _$PlayerStateImpl _value, $Res Function(_$PlayerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentSong = freezed,
    Object? queue = null,
    Object? currentIndex = null,
    Object? currentPosition = null,
    Object? isPlaying = null,
    Object? isBuffering = null,
    Object? shuffleMode = null,
    Object? repeatMode = null,
    Object? currentPlaylistId = freezed,
  }) {
    return _then(_$PlayerStateImpl(
      currentSong: freezed == currentSong
          ? _value.currentSong
          : currentSong // ignore: cast_nullable_to_non_nullable
              as Song?,
      queue: null == queue
          ? _value._queue
          : queue // ignore: cast_nullable_to_non_nullable
              as List<Song>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPosition: null == currentPosition
          ? _value.currentPosition
          : currentPosition // ignore: cast_nullable_to_non_nullable
              as Duration,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isBuffering: null == isBuffering
          ? _value.isBuffering
          : isBuffering // ignore: cast_nullable_to_non_nullable
              as bool,
      shuffleMode: null == shuffleMode
          ? _value.shuffleMode
          : shuffleMode // ignore: cast_nullable_to_non_nullable
              as bool,
      repeatMode: null == repeatMode
          ? _value.repeatMode
          : repeatMode // ignore: cast_nullable_to_non_nullable
              as RepeatMode,
      currentPlaylistId: freezed == currentPlaylistId
          ? _value.currentPlaylistId
          : currentPlaylistId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerStateImpl implements _PlayerState {
  const _$PlayerStateImpl(
      {this.currentSong,
      final List<Song> queue = const [],
      this.currentIndex = 0,
      this.currentPosition = Duration.zero,
      this.isPlaying = false,
      this.isBuffering = false,
      this.shuffleMode = false,
      this.repeatMode = RepeatMode.off,
      this.currentPlaylistId})
      : _queue = queue;

  factory _$PlayerStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerStateImplFromJson(json);

  @override
  final Song? currentSong;
  final List<Song> _queue;
  @override
  @JsonKey()
  List<Song> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final Duration currentPosition;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final bool isBuffering;
  @override
  @JsonKey()
  final bool shuffleMode;
  @override
  @JsonKey()
  final RepeatMode repeatMode;
  @override
  final String? currentPlaylistId;

  @override
  String toString() {
    return 'PlayerState(currentSong: $currentSong, queue: $queue, currentIndex: $currentIndex, currentPosition: $currentPosition, isPlaying: $isPlaying, isBuffering: $isBuffering, shuffleMode: $shuffleMode, repeatMode: $repeatMode, currentPlaylistId: $currentPlaylistId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.currentSong, currentSong) ||
                other.currentSong == currentSong) &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.currentPosition, currentPosition) ||
                other.currentPosition == currentPosition) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.isBuffering, isBuffering) ||
                other.isBuffering == isBuffering) &&
            (identical(other.shuffleMode, shuffleMode) ||
                other.shuffleMode == shuffleMode) &&
            (identical(other.repeatMode, repeatMode) ||
                other.repeatMode == repeatMode) &&
            (identical(other.currentPlaylistId, currentPlaylistId) ||
                other.currentPlaylistId == currentPlaylistId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentSong,
      const DeepCollectionEquality().hash(_queue),
      currentIndex,
      currentPosition,
      isPlaying,
      isBuffering,
      shuffleMode,
      repeatMode,
      currentPlaylistId);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerStateImplToJson(
      this,
    );
  }
}

abstract class _PlayerState implements PlayerState {
  const factory _PlayerState(
      {final Song? currentSong,
      final List<Song> queue,
      final int currentIndex,
      final Duration currentPosition,
      final bool isPlaying,
      final bool isBuffering,
      final bool shuffleMode,
      final RepeatMode repeatMode,
      final String? currentPlaylistId}) = _$PlayerStateImpl;

  factory _PlayerState.fromJson(Map<String, dynamic> json) =
      _$PlayerStateImpl.fromJson;

  @override
  Song? get currentSong;
  @override
  List<Song> get queue;
  @override
  int get currentIndex;
  @override
  Duration get currentPosition;
  @override
  bool get isPlaying;
  @override
  bool get isBuffering;
  @override
  bool get shuffleMode;
  @override
  RepeatMode get repeatMode;
  @override
  String? get currentPlaylistId;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}


