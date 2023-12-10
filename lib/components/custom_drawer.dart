import 'package:flutter/material.dart';
import 'package:plow_project/components/user_provider.dart';

class CustomDrawer extends StatelessWidget {
  final UserProvider userProvider;

  CustomDrawer({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Profile Info',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.red), // 로그아웃 아이콘
                SizedBox(width: 8.0), // 아이콘과 텍스트 간격 조절
                Text('Logout', style: TextStyle(color: Colors.red)), // 로그아웃 텍스트
              ],
            ),
            contentPadding: EdgeInsets.only(bottom: 16.0),
            onTap: () async {
              await userProvider.signOut('Logout');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
