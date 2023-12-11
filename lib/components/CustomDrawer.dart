import 'package:flutter/material.dart';
import 'package:plow_project/components/Size.dart';
import 'package:plow_project/components/UserProvider.dart';

class CustomDrawer extends StatelessWidget {
  final UserProvider userProvider;

  CustomDrawer({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사용자 프로필 사진
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.account_circle),
                  ),
                ),
                Divider(
                  color: Colors.grey,
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                ),
                // 사용자 이름
                Expanded(
                  child: Center(
                    child: Text(
                      // 'name',
                      userProvider.userName!,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                // 사용자 이메일
                Expanded(
                  child: Center(
                    child: Text(
                      // 'email',
                      userProvider.userEmail!,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0), // 원하는 indent 값 설정
                  child: Icon(Icons.person, color: Colors.blue), // userInfo 아이콘
                ),
                SizedBox(width: largeGap), // 아이콘과 텍스트 간격 조절
                Text('나의 정보', style: TextStyle(color: Colors.blue)),
              ],
            ),
            contentPadding: EdgeInsets.only(bottom: 4.0),
            onTap: () => Navigator.pushNamed(context, '/MyInfoView'),
          ), // 사용자 정보(My Info View)
          Divider(
            color: Colors.grey,
            thickness: 1,
            height: 10,
          ),
          ListTile(
            title: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16.0), // 원하는 indent 값 설정
                  child: Icon(Icons.exit_to_app, color: Colors.red), // userInfo 아이콘
                ),
                SizedBox(width: largeGap),
                Text('Logout', style: TextStyle(color: Colors.red)),
              ],
            ),
            contentPadding: EdgeInsets.only(bottom: 16.0),
            onTap: () async {
              await userProvider.signOut('Logout');
              Navigator.pushReplacementNamed(context, '/LoginView');
            },
          ), // 로그아웃
        ],
      ),
    );
  }
}
