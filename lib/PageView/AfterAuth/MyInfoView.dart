import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomDrawer.dart';
import '../../components/CustomClass/CustomTextField.dart';
import '../../components/UserProvider.dart';

class MyInfoView extends StatefulWidget {
  @override
  State<MyInfoView> createState() => _MyInfoViewState();
}

class _MyInfoViewState extends State<MyInfoView> {
  final TextEditingController nameController = TextEditingController();
  late UserProvider userProvider;
  bool isEditing = false;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    nameController.text = userProvider.userName!;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '나의 정보'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Row(
            children: [
              GestureDetector(
                child: isEditing
                    ? Icon(
                        Icons.save,
                        color: Colors.white,
                      )
                    : Icon(Icons.edit, color: Colors.white),
                onTap: () async {
                  if (isEditing) {
                    await userProvider.setName(nameController.text);
                  }
                  setState(() => isEditing = !isEditing);
                },
              ), // 수정하기 버튼
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            ],
          )
        ],
      ),
      drawer: CustomDrawer(
        userProvider: userProvider,
        drawerItems: [
          DrawerItem(
              icon: Icons.exit_to_app,
              color: Colors.red,
              text: '로그아웃',
              route: '/LoginView'),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.account_circle, size: 120),
              ),
            ),
            Divider(
              color: Colors.grey,
              thickness: 4,
              indent: 20,
              endIndent: 20,
              height: 40,
            ),
            CustomTextField(
              controller: nameController,
              icon: Icon(Icons.badge),
              isReadOnly: !isEditing,
            ),
            CustomTextField(
              hintText: userProvider.userEmail,
              icon: Icon(Icons.email),
              isReadOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
