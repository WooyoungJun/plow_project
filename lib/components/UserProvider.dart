import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'CustomClass/CustomToast.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

class UserProvider extends ChangeNotifier {
  final CollectionReference _userInfo =
      FirebaseFirestore.instance.collection('UserInfo');
  final FirebaseAuth _auth; // 파이어베이스 Auth 객체 인스턴스
  Status _status; // 현재 사용자 상태
  User? _user; // 사용자의 정보 담고 있는 객체
  List<String> _friend = []; // 친구 uid 저장

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
  String? get uid => _user?.email;

  String get userEmail => _user?.email ?? '알수없음';

  String get userName => _user?.displayName ?? '이름을 설정하세요';

  List<String> get friend => _friend;

  IconData? get icon => _icon ?? Icons.account_circle;

  // 상태 변경 시 user 객체가 스트림으로 들어옴
  Future<void> _onStateChanged(User? user) async {
    if (user == null) {
      _status = Status.unauthenticated;
    } else {
      _status = Status.authenticated;
      _user = user;
      var docRef = await _userInfo.doc(_user!.email).get();
      _friend = docRef['friendEmail'].cast<String>();
    }
  }

  Future<void> addFriend(String friendEmail) async {
    try {
      friendEmail = friendEmail.trim();
      if (_user == null) return CustomToast.showToast('사용자를 찾을 수 없습니다!');
      if (friendEmail.isEmpty) return CustomToast.showToast('이메일을 입력해주세요!');
      if (_friend.contains(friendEmail)) {
        return CustomToast.showToast('이미 친구상태입니다!');
      }
      if (!((await _userInfo.doc(friendEmail).get()).exists)) {
        return CustomToast.showToast('해당하는 이메일로 가입한 유저를 찾을 수 없습니다!');
      }
      await _userInfo.doc(_user!.email).update({
        'friendEmail': FieldValue.arrayUnion([friendEmail])
      });
      await _userInfo.doc(friendEmail).update({
        'friendEmail': FieldValue.arrayUnion([_user!.email])
      });
      _friend.add(friendEmail);
      return CustomToast.showToast('친구 추가 완료!');
    } catch (err) {
      CustomToast.showToast('친구 추가 오류: $err');
      print(err);
    }
  }

  Future<void> deleteFriend(String friendEmail) async {
    try {
      friendEmail = friendEmail.trim();
      if (_user == null) return CustomToast.showToast('사용자를 찾을 수 없습니다!');
      if (friendEmail.isEmpty) return CustomToast.showToast('이메일을 입력해주세요!');
      if (!(_friend.contains(friendEmail))) {
        return CustomToast.showToast('친구상태가 아닙니다!');
      }
      await _userInfo.doc(_user!.email).update({
        'friendEmail': FieldValue.arrayRemove([friendEmail])
      });
      await _userInfo.doc(friendEmail).update({
        'friendEmail': FieldValue.arrayRemove([_user!.email])
      });
      _friend.remove(friendEmail);
      return CustomToast.showToast('친구 삭제 완료!');
    } catch (err) {
      CustomToast.showToast('친구 삭제 오류: $err');
      print(err);
    }
  }

  // userName 변경
  Future<void> setName(String name) async {
    if (_user != null) {
      var curName = _user!.displayName;
      if (curName != name) {
        await _user!.updateDisplayName(name); // 이름 초기값 설정
        await _user!.reload(); // 변경사항 적용
        _user = _auth.currentUser; // 변경된 객체 다시 적용
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
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _friend.add(email);
      await _userInfo.doc(email).set({
        'credit': 0,
        'friendEmail': _friend,
      }); // credit 초기화
      await _user!.updateDisplayName(email); // 이름 초기값 설정
      await _user!.reload(); // 변경사항 적용
      _user = _auth.currentUser; // 변경된 객체 다시 적용
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
      var docRef = await _userInfo.doc(email).get();
      print(docRef.data());
      _friend = docRef['friendEmail'].cast<String>();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
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
    _friend.clear();
    // print('$buttonText 성공');
    CustomToast.showToast('$buttonText 성공');
  }

  Future<void> resetPassword(String email) async {
    try {
      // 이메일이 Firebase Authentication에 존재하는지 확인
      try {
        await _auth.fetchSignInMethodsForEmail(email);
      } catch (err) {
        return CustomToast.showToast(err.toString());
      }
      await _auth.sendPasswordResetEmail(email: email);
      CustomToast.showToast('비밀번호 재설정 이메일이 전송되었습니다.');
    } catch (e) {
      print("비밀번호 재설정 이메일 전송 실패: $e");
    }
  }
}
