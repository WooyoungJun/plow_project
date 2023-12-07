// 로그인 시 나오는 화면
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import 'components/user_provider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
        child: Text(
          "Welcome, ${userProvider.user?.email ?? 'Anonymous'}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
