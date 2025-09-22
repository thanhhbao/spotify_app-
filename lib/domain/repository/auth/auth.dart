/*AuthRepository: Có thể được sử dụng để định nghĩa các giao diện 
hoặc các lớp cơ sở cho các dịch vụ xác thực khác nhau trong dự án. 
Điều này có thể bao gồm việc xác thực không chỉ qua Firebase mà còn qua các 
phương pháp khác như cơ sở dữ liệu nội bộ hoặc dịch vụ khác.
*/
import 'package:dartz/dartz.dart';
import 'package:spotify_app/data/models/auth/create_user_req.dart';
import 'package:spotify_app/data/models/auth/signin_user_req.dart';

abstract class AuthRepository {
  Future<Either> signup(CreateUserReq createUserReq);

  Future<Either> signin(SigninUserReq signinUserReq);
}
