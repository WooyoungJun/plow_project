import 'package:flutter/material.dart';
import 'package:plow_project/components/Size.dart';
import 'package:plow_project/components/UserProvider.dart';

class DrawerItem {
  final IconData icon;
  final Color color;
  final String text;
  final String route;

  DrawerItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.route,
  });
}

class CustomDrawer extends StatelessWidget {
  final UserProvider userProvider;
  final List<DrawerItem> drawerItems;

  CustomDrawer({
    required this.userProvider,
    required this.drawerItems,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: drawerItems.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Center(
              child: UserAccountsDrawerHeader(
                currentAccountPicture: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(userProvider.icon, size: 60.0),
                  ),
                ),
                accountName: Text(
                  userProvider.userName!,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                accountEmail: Text(
                  userProvider.userEmail!,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                onDetailsPressed: () {},
                decoration: BoxDecoration(
                  color: Colors.red[200],
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40.0),
                    bottomRight: Radius.circular(40.0),
                  ),
                ),
              ),
            ); // User 이미지, 이름, email 표시
          } else {
            final item = drawerItems[index - 1]; // Subtracting 1 for the header
            return ListTile(
              title: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Icon(item.icon, color: item.color),
                  ),
                  SizedBox(width: largeGap),
                  Text(item.text, style: TextStyle(color: item.color)),
                ],
              ),
              contentPadding: EdgeInsets.only(bottom: 4.0),
              onTap: () {
                if (item.route == '/LoginView') {
                  userProvider.signOut('signOut');
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/LoginView',
                    (route) => false, // 모든 스택을 제거하고 '/LoginView'로 이동
                  );
                } else {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, item.route);
                }
              },
            );
          }
        },
      ),
    );
  }
}
