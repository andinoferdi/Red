import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';

part 'playlist_state.freezed.dart';
part 'playlist_state.g.dart';

@freezed
class PlaylistState with _$PlaylistState {
  const factory PlaylistState({
    @Default([]) List<Playlist> playlists,
    Playlist? currentPlaylist,
    Song? currentSong,
    @Default(false) bool isLoading,
    String? error,
  }) = _PlaylistState;

  factory PlaylistState.fromJson(Map<String, dynamic> json) =>
      _$PlaylistStateFromJson(json);
}
