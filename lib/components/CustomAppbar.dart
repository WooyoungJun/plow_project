import 'package:flutter/material.dart';
import 'package:plow_project/components/UserProvider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final UserProvider userProvider;
  final List<Widget>? actions;

  CustomAppBar({required this.title, required this.userProvider, this.actions});

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
      actions: actions ??
          [
            IconButton(
              icon: Icon(Icons.menu),
              // 가장 가까운 부모 Scaffold 위젯
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ],
    );
  }
}
