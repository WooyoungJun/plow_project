import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

// FirebaseAuth, status(로그인 상태), User객체 가지고 있음
class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth; // 파이어베이스 Auth 객체 인스턴스
  Status _status; // 유저의 현재 상태
  User? _user; //
  List<String> friend = [];

  UserProvider()
      : _auth = FirebaseAuth.instance,
        _user = FirebaseAuth.instance.currentUser,
        _status = FirebaseAuth.instance.currentUser != null
            ? Status.authenticated
            : Status.unauthenticated {
    // 사용자 정보 변경시 이벤트 발생 메소드 -> 해당 event listen
    _auth.authStateChanges().listen(_onStateChanged);
  }

  IconData? _icon;

  User? get user => _user;

  // 유저의 현재 상태 (uninitialized, authenticated, authenticating, unauthenticated)
  Status get status => _status;

  // 유저의 이메일, 이름, 번호 저장
  String? get uid => _user?.uid;

  String? get userEmail => _user?.email ?? '알수없음';

  String? get userName => _user?.displayName ?? '이름을 설정하세요';

  IconData? get icon => _icon ?? Icons.account_circle;

  // 상태 변경 시 user 객체가 스트림으로 들어옴
  // 해당 객체 저장
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

  Future<void> setName(String name) async {
    if (_user != null) {
      var curName = _user!.displayName;
      if (curName != name) {
        await _user!.updateDisplayName(name);
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
        if (_user!.displayName == name) {
          showToast('이름 변경 완료!');
        } else {
          showToast('이름 변경 실패!');
          print('ㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇㅇ: ${_user!.displayName}');
        }
      } else {
        showToast('수정된 사항이 없습니다!');
      }
    } else {
      showToast('변경 사항이 없습니다!');
    }
  }

  Future<String> signUpOrIn(
      String email, String password, String buttonText, bool isUp) async {
    try {
      if (isUp) {
        // signUp
        // 생성 완료시 user 객체가 stream으로 전달
        // 해당 객체가 _onStateChanged로 전달되어서 _user에 저장
        // firebase에 해당 객체의 uid, userEmail, userName(default='') 저장
        var userCredential = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        // 새로운 Firestore 문서 생성 및 uid로 문서 ID 설정
        await FirebaseFirestore.instance
            .collection('UserInfo')
            .doc(userCredential.user!.uid)
            .set({'credit': 0});
      } else {
        // signIn
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
      }
      print('$buttonText 성공');
      showToast('$buttonText 성공');
      return '성공';
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      return e.message!;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signUp(
          String email, String password, String buttonText) async =>
      signUpOrIn(email, password, buttonText, true);

  Future<String> signIn(
          String email, String password, String buttonText) async =>
      signUpOrIn(email, password, buttonText, false);

  Future<void> signOut(String buttonText) async {
    await _auth.signOut();
    notifyListeners();
    print('$buttonText 성공');
    showToast('$buttonText 성공');
  }
}

void showToast(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      webPosition: 'center',
      // 토스트 위치 = 중앙
      toastLength: Toast.LENGTH_SHORT,
      // 토스트 길이 짧게
      gravity: ToastGravity.TOP,
      // 위로 중력 설정
      timeInSecForIosWeb: 3,
      // 3초 유지
      webShowClose: true,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0);
}
