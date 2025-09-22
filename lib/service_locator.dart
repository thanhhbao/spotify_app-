import 'package:get_it/get_it.dart';
import 'package:spotify_app/data/repository/auth/auth_repository_impl.dart';

import 'package:spotify_app/data/sources/auth/auth_firebase_service.dart';

import 'package:spotify_app/domain/repository/auth/auth.dart';

import 'package:spotify_app/domain/usecases/auth/signup.dart';
import 'package:spotify_app/domain/usecases/song/get_new_songs.dart';
import 'package:spotify_app/domain/usecases/song/get_play_list.dart';

import 'data/repository/song/song_repository_impl.dart';
import 'data/sources/song/song_firebase_service.dart';
import 'domain/repository/song/song.dart';
import 'domain/usecases/auth/signin.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  /*Dăng ký một instance của AuthFirebaseServiceImpl cho giao diện AuthFirebaseService. 
  Điều này có nghĩa là bất kỳ nơi nào yêu cầu một đối tượng kiểuAuthFirebaseService 
  sẽ nhận được cùng một instance của AuthFirebaseServiceImpl.*/

  sl.registerSingleton<AuthFirebaseService>(
      AuthFirebaseServiceImpl()); //sl = service locator

  sl.registerSingleton<SongFirebaseService>(SongFirebaseServiceImpl());

/*sl.registerSingleton<AuthRepository>(AuthRepositoryImpl()) tương tự đăng ký 
một instance của AuthRepositoryImpl cho giao diện AuthRepository.*/

  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl());

  sl.registerSingleton<SongsRepository>(SongRepositoryImpl());

  sl.registerSingleton<SignupUseCase>(SignupUseCase());

  sl.registerSingleton<SigninUseCase>(SigninUseCase());

  sl.registerSingleton<GetNewsSongsUseCase>(GetNewsSongsUseCase());

  sl.registerSingleton<GetPlayListUseCase>(GetPlayListUseCase());
}
