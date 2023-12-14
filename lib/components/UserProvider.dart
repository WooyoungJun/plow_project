import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'CustomClass/CustomToast.dart';

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

  // 유저 uid를 사용, FirebaseFirestore에 데이터 저장하고 관리
  Future<void> addFriend(String friendUid) async {
    try {
      if (_user != null) {
        // Firestore 데이터베이스에 사용자의 친구 목록을 업데이트
        // 찾아보니 FirebaseAuth는 사용자 인증/관리에 초점 맞추고 있고,
        // 친구 부분은 사용자 인증보다는 데이터 저장/관리에 넣어야 할 것 같아서 이렇게 작성
        await FirebaseFirestore.instance
            .collection('UserInfo')
            .doc(_user!.uid) // 현재 로그인한 사용자의 UID
            .update({
          'friends': FieldValue.arrayUnion([friendUid]), // 친구의 UID를 추가
        });

        // 로컬 친구 목록에도 추가
        friend.add(friendUid);
        CustomToast.showToast('친구 추가 완료!');
      } else {
        CustomToast.showToast('사용자를 인식할 수 없습니다!');
      }
    } catch (e) {
      CustomToast.showToast('친구 추가 오류: $e');
    }
  }

  // userName 변경
  Future<void> setName(String name) async {
    if (_user != null) {
      var curName = _user!.displayName;
      if (curName != name) {
        await _user!.updateDisplayName(name);
        await _user!.reload();
        _user = FirebaseAuth.instance.currentUser;
        if (_user!.displayName == name) {
          CustomToast.showToast('이름 변경 완료!');
        } else {
          CustomToast.showToast('이름 변경 실패!');
        }
      } else {
        CustomToast.showToast('수정된 사항이 없습니다!');
      }
    } else {
      CustomToast.showToast('변경 사항이 없습니다!');
    }
  }

  // 회원 가입
  Future<String> signUp(
      String email, String password, String buttonText) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await FirebaseFirestore.instance
          .collection('UserInfo')
          .doc(userCredential.user!.uid)
          .set({'credit': 0}); // credit 초기화
      // print('$buttonText 성공');
      CustomToast.showToast('$buttonText 성공');
      return '성공';
    } on FirebaseAuthException catch (err) {
      return err.message!;
    } catch (err) {
      return err.toString();
    }
  }

  Future<String> signIn(
          String email, String password, String buttonText) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // print('$buttonText 성공');
      CustomToast.showToast('$buttonText 성공');
      return '성공';
    } on FirebaseAuthException catch (err) {
      return err.message!;
    } catch (err) {
      return err.toString();
    }
  }

  Future<void> signOut(String buttonText) async {
    await _auth.signOut();
    _user = null;
    // print('$buttonText 성공');
    CustomToast.showToast('$buttonText 성공');
  }
}