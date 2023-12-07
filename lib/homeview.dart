// 로그인 시 나오는 화면
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
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
