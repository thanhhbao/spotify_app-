import 'package:dartz/dartz.dart';
import 'package:spotify_app/domain/entities/song/song.dart';
import 'package:spotify_app/domain/repository/song/song.dart';
import '../../../service_locator.dart';
import '../../sources/song/song_firebase_service.dart';

class SongRepositoryImpl extends SongsRepository {
  @override
  Future<Either<String, List<SongEntity>>> getNewsSongs() async {
    try {
      // Lấy dữ liệu từ SongFirebaseService
      final result = await sl<SongFirebaseService>().getNewsSongs();

      // Xử lý kết quả từ SongFirebaseService
      return result.fold(
        (failure) => Left(failure), // Trả về lỗi nếu có
        (songs) => Right(songs), // Trả về danh sách bài hát nếu thành công
      );
    } catch (e) {
      return const Left('An unexpected error occurred.');
    }
  }

  @override
  Future<Either> getPlayList() async {
    return await sl<SongFirebaseService>().getPlayList();
  }
}
