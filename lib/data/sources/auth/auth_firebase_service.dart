/*AuthFirebaseService: Được thiết kế cụ thể cho các thao tác liên quan đến Firebase.
 Đây  là một lớp giao diện để định nghĩa cách thức cụ thể cho việc tích hợp Firebase
  trong ứng dụng.*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spotify_app/data/models/auth/create_user_req.dart';
import 'package:spotify_app/data/models/auth/signin_user_req.dart';

abstract class AuthFirebaseService {
  Future<Either> signup(CreateUserReq createUserReq);

  Future<Either> signin(SigninUserReq signinUserReq);
}

class AuthFirebaseServiceImpl extends AuthFirebaseService {
  @override
  Future<Either> signin(SigninUserReq signinUserReq) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: signinUserReq.email, password: signinUserReq.password);

      return const Right('Signin was Successful');
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'invalid-email') {
        message = 'Not user found for that email';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided for that user';
      }

      return Left(message);
    }
  }

  @override
  Future<Either> signup(CreateUserReq createUserReq) async {
    try {
      var data = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: createUserReq.email, password: createUserReq.password);

      // Kiểm tra xem người dùng có tồn tại không
      if (data.user != null) {
        // Thêm dữ liệu vào bộ sưu tập Users
        await FirebaseFirestore.instance.collection('Users').add({
          'name': createUserReq.fullName,
          'email': createUserReq.email,
        });

        return const Right('Signup was Successful');
      } else {
        return const Left('User creation failed');
      }
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email.';
      }

      return Left(message);
    } catch (e) {
      return Left('An unexpected error occurred: ${e.toString()}');
    }
  }
}
