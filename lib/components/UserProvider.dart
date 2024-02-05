import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

class UserProvider extends ChangeNotifier {
  static final FirebaseFirestore _store = FirebaseFirestore.instance;
  static final CollectionReference _userInfoRef = _store.collection('UserInfo');
  final FirebaseAuth _auth; // 파이어베이스 Auth 객체 인스턴스

  Status _status; // 현재 사용자 상태
  User? _user; // 사용자의 정보 담고 있는 객체

  int _count = 0;
  int _credit = 0;
  Map<String, dynamic> _dailyQuestStatus = {};
  List<String> _friend = [];
  String _userName = '';
  IconData? _icon;

  static Future<String?> getUserName(String email) async {
    return (await _userInfoRef.doc(email).get())['userName'];
  }

  DocumentReference get _userDoc => _userInfoRef.doc(_user!.email);

  Status get status => _status;

  String get uid => _user?.email ?? '';

  int get count => _count;

  int get credit => _credit;

  Map<String, dynamic> get dailyQuestStatus => _dailyQuestStatus;

  List<String> get friend => _friend;

  String get userName => _userName;

  IconData? get icon => _icon ?? Icons.account_circle;

  UserProvider()
      : _auth = FirebaseAuth.instance,
        _user = null,
        _status = Status.unauthenticated {
    _auth.authStateChanges().listen(_onStateChanged);
  }

  Future<void> _onStateChanged(User? user) async {
    _user = user;
    _status = _user != null ? Status.authenticated : Status.unauthenticated;
  }

  Future<Timestamp> getStatus() async {
    Map<String, dynamic> userInfo =
        (await _userDoc.get()).data() as Map<String, dynamic>;
    _count = userInfo['count'] as int;
    _credit = userInfo['credit'] as int;
    _friend = userInfo['friendEmail'].cast<String>();
    _dailyQuestStatus = userInfo['dailyQuestStatus'] as Map<String, dynamic>;
    _userName = userInfo['userName'] as String;
    return userInfo['lastQuestReset'] as Timestamp;
  }

  bool canGetCredit() {
    return _dailyQuestStatus['postCount'] >= 3 &&
        !_dailyQuestStatus['creditReceived'];
  }

  Future<void> getCredit() async {
    await _store.runTransaction((transaction) async {
      _dailyQuestStatus['creditReceived'] = true;
      transaction.update(_userDoc, {
        'credit': FieldValue.increment(1),
        'dailyQuestStatus': _dailyQuestStatus,
      });
    });
    await getStatus();
  }

  Future<void> resetDailyQuests() async {
    await _userInfoRef.doc(uid).update({
      'dailyQuestStatus': {
        'creditReceived': false,
        'postCount': 3,
      }
    });
    await getStatus();
  }

  Future<void> setName(String name) async {
    try {
      if (_user != null) {
        if (_userName != name) {
          await _userInfoRef.doc(_user!.email).update({'userName': name});
          _userName = name;
          CustomToast.showToast('이름 변경 완료!');
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

  Future<void> addFriend(String friendEmail) async {
    try {
      friendEmail = friendEmail.trim();
      if (_user == null) return CustomToast.showToast('사용자를 찾을 수 없습니다!');
      if (friendEmail.isEmpty) return CustomToast.showToast('이메일을 입력해주세요!');
      if (_friend.contains(friendEmail)) {
        return CustomToast.showToast('이미 친구상태입니다!');
      }
      if (!((await _userInfoRef.doc(friendEmail).get()).exists)) {
        return CustomToast.showToast('해당하는 이메일로 가입한 유저를 찾을 수 없습니다!');
      }
      await _store.runTransaction((transaction) async {
        transaction.update(_userDoc, {
          'friendEmail': FieldValue.arrayUnion([friendEmail]),
        });

        transaction.update(_userInfoRef.doc(friendEmail), {
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
        transaction.update(_userDoc, {
          'friendEmail': FieldValue.arrayRemove([friendEmail])
        });
        transaction.update(_userInfoRef.doc(friendEmail), {
          'friendEmail': FieldValue.arrayRemove([friendEmail])
        });
      });
      return CustomToast.showToast('친구 삭제 완료!');
    } catch (err) {
      CustomToast.showToast('친구 삭제 오류: $err');
      print(err);
    }
  }

  Future<String> signUp(
      {required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _userInfoRef.doc(email).set({
        'userName': email,
        'count': 0,
        'credit': 0,
        'friendEmail': [email],
        'dailyQuestStatus': {
          'creditReceived': false,
          'postCount': 0,
        },
        'lastQuestReset': FieldValue.serverTimestamp(),
      }); // credit 초기화
      _friend = [email];
      _userName = email;
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
      Timestamp before = await getStatus();
      // 이전 접속 날짜와 현재 날짜 비교
      if (before.toDate().day != DateTime.now().day) {
        // 일일 퀘스트 리셋
        await resetDailyQuests();
      }
      await _store.runTransaction((transaction) async {
        transaction.update(_userDoc, {
          'lastQuestReset': FieldValue.serverTimestamp(),
        });
      });
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
      CustomToast.showToast('Sign Out 성공');
    } catch (err) {
      CustomToast.showToast('Sign Out 에러: $err');
      print(err);
    }
  }

  void resetStatus() {
    _count = 0;
    _credit = 0;
    _dailyQuestStatus = {};
    _friend = [];
    _userName = '';
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
