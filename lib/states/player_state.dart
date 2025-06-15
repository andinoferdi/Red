import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/song.dart';

part 'player_state.g.dart';
part 'player_state.freezed.dart';

/// Enum for repeat mode
enum RepeatMode {
  off,
  all,
  one,
}

/// State for music player
@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    Song? currentSong,
    @Default([]) List<Song> queue,
    @Default(0) int currentIndex,
    @Default(Duration.zero) Duration currentPosition,
    @Default(false) bool isPlaying,
    @Default(false) bool isBuffering,
    @Default(false) bool shuffleMode,
    @Default(RepeatMode.off) RepeatMode repeatMode,
    String? currentPlaylistId,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) => _$PlayerStateFromJson(json);
  
  /// Initial state
  factory PlayerState.initial() => const PlayerState();
}


