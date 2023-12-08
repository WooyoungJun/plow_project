import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

// FirebaseAuth, status(로그인 상태), User객체 가지고 있음
class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  Status _status;
  User? _user;

  Status get status => _status;

  User? get user => _user;

  // user 생성자
  UserProvider()
      : _auth = FirebaseAuth.instance,
        _user = FirebaseAuth.instance.currentUser,
        _status = FirebaseAuth.instance.currentUser != null
            ? Status.authenticated
            : Status.unauthenticated {
    // 사용자 정보 변경시 이벤트 발생 메소드 -> 해당 event listen
    _auth.authStateChanges().listen(_onStateChanged);
  }

  Future<void> _onStateChanged(User? user) async {
    if (user == null) {
      _status = Status.unauthenticated;
    } else {
      _status = Status.authenticated;
      _user = user;
    }
    notifyListeners();
    // 사용자 정보 변경 시 해당 코드 실행
    // -> Consumer 코드 다시 실행 되면서 화면 다시 build
  }

  Future<String> signUp(String email, String password, String buttonText) async {
    try {
      // 생성 완료시 currentUser 현재 정보 저장
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      print('$buttonText 성공');
      showToast('$buttonText 성공');
      return '성공';
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      // notifyListeners();
      return e.message!;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signIn(String email, String password, String buttonText) async {
    try {
      // _status = Status.authenticating;
      // notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('$buttonText 성공');
      showToast('$buttonText 성공');
      return '성공';
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return e.message!;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut(String buttonText) async {
    await _auth.signOut();
    print('$buttonText 성공');
    showToast('$buttonText 성공');
  }
}

void showToast(String msg){
  Fluttertoast.showToast(
      msg: msg,
      webPosition: 'center', // 토스트 위치 = 중앙
      toastLength: Toast.LENGTH_SHORT, // 토스트 길이 짧게
      gravity: ToastGravity.TOP, // 위로 중력 설정
      timeInSecForIosWeb: 3, // 3초 유지
      webShowClose: true,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0);
}