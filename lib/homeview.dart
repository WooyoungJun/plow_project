// 로그인 시 나오는 화면
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'components/user_provider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  // user가 작성한 문서 읽어오기
  Future<void> readData(UserProvider user) async {
    // 쿼리 실행
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("BoardList") // collection 이름
        .where('member_id', isEqualTo: user.user!.uid)
        .get(); // member_id로 검색
    // 쿼리 결과 처리
    for (var doc in querySnapshot.docs) {
      print('post id : ${doc.id}');
      print('title : ${doc['title']}');
      print('content : ${doc['content']}');
      print('created date : ${doc['created_date']}');
      print('member id : ${doc['member_id']}');
    }
  }

  // post 데이터베이스에 추가
  Future<void> addPost(String title, String content, UserProvider user) async {
    // 유효성 검사 확인 필요
    
    CollectionReference posts =
        FirebaseFirestore.instance.collection('BoardList');
    await posts.add({
      'title': title,
      'content': content,
      'created_date': FieldValue.serverTimestamp(),
      'member_id': user.user!.uid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    print('Home ${userProvider.user?.email}'); // user email 출력
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text("Logout"),
            onPressed: () async {
              await userProvider.signOut();
              Fluttertoast.showToast(
                  msg: 'logout 성공!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  timeInSecForIosWeb: 5,
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 16.0);
              Navigator.pushReplacementNamed(
                context,
                '/login',
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome, ${userProvider.user?.email ?? 'Anonymous'}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "your ID is ${userProvider.user?.uid ?? 'Anonymous'}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
