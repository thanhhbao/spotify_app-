import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify_app/presentation/song_player/bloc/song_player_state.dart';

class SongPlayerCubit extends Cubit<SongPlayerState> {
  final AudioPlayer audioPlayer = AudioPlayer();

  Duration songDuration = Duration.zero;
  Duration songPosition = Duration.zero;

  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  SongPlayerCubit() : super(SongPlayerLoading());

  Future<void> loadSong(String url) async {
    emit(SongPlayerLoading());
    try {
      // URL phải là file âm thanh thực sự (.mp3/.m4a/...)
      await audioPlayer.setUrl(url);

      // giá trị ban đầu (an toàn với null)
      songDuration = audioPlayer.duration ?? Duration.zero;
      songPosition = audioPlayer.position;

      // lắng nghe duration
      await _durSub?.cancel();
      _durSub = audioPlayer.durationStream.listen((d) {
        songDuration = d ?? Duration.zero;
        emit(SongPlayerLoaded());
      });

      // lắng nghe position
      await _posSub?.cancel();
      _posSub = audioPlayer.positionStream.listen((p) {
        songPosition = p;
        emit(SongPlayerLoaded());
      });

      // lắng nghe trạng thái play/pause/buffer…
      await _playerStateSub?.cancel();
      _playerStateSub = audioPlayer.playerStateStream.listen((_) {
        emit(SongPlayerLoaded());
      });

      emit(SongPlayerLoaded());
    } catch (_) {
      emit(SongPlayerFailure());
    }
  }

  void playOrPauseSong() {
    if (audioPlayer.playing) {
      audioPlayer.pause(); // dùng pause để giữ nguyên vị trí
    } else {
      audioPlayer.play();
    }
    emit(SongPlayerLoaded());
  }

  Future<void> seek(Duration position) async {
    final max = songDuration;
    final target = position > max ? max : position;
    await audioPlayer.seek(target);
  }

  @override
  Future<void> close() async {
    await _durSub?.cancel();
    await _posSub?.cancel();
    await _playerStateSub?.cancel();
    await audioPlayer.dispose();
    return super.close();
  }
}
