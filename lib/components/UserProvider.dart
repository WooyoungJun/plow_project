import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

class UserProvider extends ChangeNotifier {
  static final FirebaseFirestore _store = FirebaseFirestore.instance;
  static final CollectionReference _userInfo = _store.collection('UserInfo');
  final FirebaseAuth _auth; // 파이어베이스 Auth 객체 인스턴스
  Status _status; // 현재 사용자 상태
  User? _user; // 사용자의 정보 담고 있는 객체
  List<String> _friend = []; // 친구 uid 저장
  Map<String, dynamic> _dailyQuestStatus = {};

  IconData? _icon;


  Map<String, dynamic> get dailyQuestStatus => _dailyQuestStatus;

  Status get status => _status;

  String? get uid => _user?.email;

  String get userEmail => _user?.email ?? '알수없음';

  String get userName => _user?.displayName ?? '이름을 설정하세요';

  List<String> get friend => _friend;

  IconData? get icon => _icon ?? Icons.account_circle;

  DocumentReference get _userDoc => _userInfo.doc(_user!.email);

  Future<Map<String, dynamic>?> get userInfo async {
    if (_user == null) return null;
    var doc = await _userDoc.get();
    return doc.data() as Map<String, dynamic>?;
  }

  UserProvider()
      : _auth = FirebaseAuth.instance,
        _user = FirebaseAuth.instance.currentUser,
        _status = FirebaseAuth.instance.currentUser != null
            ? Status.authenticated
            : Status.unauthenticated {
    _auth.authStateChanges().listen(_onStateChanged);
  }

  Future<void> _onStateChanged(User? user) async {
    _user = FirebaseAuth.instance.currentUser;
    _status = _user != null ? Status.authenticated : Status.unauthenticated;
    if (_user != null) await getStatus();
  }

  Future<void> getStatus({bool? isSign}) async {
    if(isSign == true){
      await _store.runTransaction((transaction) async {
        // var questStatus = await _userDoc.get();
      });
      await _userDoc.update({});
    }
    DocumentSnapshot docRef = await _userInfo.doc(_user!.email).get();
    _friend = docRef['friendEmail'].cast<String>();
    _dailyQuestStatus = docRef['dailyQuestStatus'] as Map<String, dynamic>;
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
      await _store.runTransaction((transaction) async {
        transaction.update(_userInfo.doc(_user!.email), {
          'friendEmail': FieldValue.arrayUnion([friendEmail]),
        });

        transaction.update(_userInfo.doc(friendEmail), {
          'friendEmail': FieldValue.arrayUnion([_user!.email]),
        });
      });
      return CustomToast.showToast('친구 추가 완료!');
    } catch (err) {
      CustomToast.showToast('친구 추가 오류: $err');
      print(err);
    }
  }

  Future<void> deleteFriend(String friendEmail) async {
    try {
      if (_user == null) return CustomToast.showToast('사용자를 찾을 수 없습니다!');
      if (friendEmail.isEmpty) return CustomToast.showToast('이메일을 입력해주세요!');
      if (!(_friend.contains(friendEmail))) {
        return CustomToast.showToast('친구상태가 아닙니다!');
      }
      await _store.runTransaction((transaction) async {
        transaction.update(_userInfo.doc(_user!.email), {
          'friendEmail': FieldValue.arrayRemove([friendEmail])
        });
        transaction.update(_userInfo.doc(friendEmail), {
          'friendEmail': FieldValue.arrayRemove([friendEmail])
        });
      });
      return CustomToast.showToast('친구 삭제 완료!');
    } catch (err) {
      CustomToast.showToast('친구 삭제 오류: $err');
      print(err);
    }
  }

  Future<void> setName(String name) async {
    try {
      if (_user != null) {
        String? curName = _user!.displayName;
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
    } catch (err) {
      CustomToast.showToast('이름 설정 오류: $err');
      print(err);
    }
  }

  Future<void> resetDailyQuests() async {}

  Future<String> signUp(
      {required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _friend.add(email);
      await _userInfo.doc(email).set({
        'count': 0,
        'credit': 0,
        'friendEmail': _friend,
        'dailyQuestStatus': {
          'postCount': 0,
          'addedFriend': false,
          'loggedIn': false,
          'creditReceived': false,
        },
        'lastQuestReset': FieldValue.serverTimestamp(),
      }); // credit 초기화
      await _user!.updateDisplayName(email); // 이름 초기값 설정
      await _user!.reload(); // 변경사항 적용
      _user = _auth.currentUser; // 변경된 객체 다시 적용
      CustomToast.showToast('Login 성공');
      return '성공';
    } on FirebaseAuthException catch (err) {
      return err.message!;
    } catch (err) {
      return err.toString();
    }
  }

  Future<String> signIn(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await getStatus();
      CustomToast.showToast('Login 성공');
      return '성공';
    } on FirebaseAuthException catch (err) {
      return err.message!;
    } catch (err) {
      return err.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = _auth.currentUser; // 변경된 객체 다시 적용
      CustomToast.showToast('Sign Out 성공');
    } catch (err) {
      CustomToast.showToast('Sign Out 에러: $err');
      print(err);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      // 이메일이 Firebase Authentication에 존재하는지 확인

      List<String> result = await _auth.fetchSignInMethodsForEmail(email);
      if (result.isEmpty) return CustomToast.showToast('계정이 없습니다');
      await _auth.sendPasswordResetEmail(email: email);
      CustomToast.showToast('비밀번호 재설정 이메일이 전송되었습니다.');
    } catch (e) {
      print("비밀번호 재설정 이메일 전송 실패: $e");
    }
  }
}
