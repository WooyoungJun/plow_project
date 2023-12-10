import 'package:flutter/material.dart';
import 'package:plow_project/components/user_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserProvider userProvider;

  CustomAppBar({required this.title, required this.userProvider});

  // AppBar return하기 위해서는 위젯 높이 필요함
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      // automaticallyImplyLeading: true, // 좌축 상단 뒤로가기 아이콘
      actions: [
        IconButton(
          icon: Icon(Icons.menu),
          // 가장 가까운 부모 Scaffold 위젯
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ), // 우측 상단 아이콘
      ],
    );
  }
}
