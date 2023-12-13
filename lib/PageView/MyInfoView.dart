import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/AppBarTitle.dart';
import '../components/CustomDrawer.dart';
import '../components/CustomTextField.dart';
import '../components/Size.dart';
import '../components/UserProvider.dart';

class MyInfoView extends StatefulWidget {
  @override
  State<MyInfoView> createState() => _MyInfoViewState();
}

class _MyInfoViewState extends State<MyInfoView> {
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

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
              Visibility(
                visible: !isEditing,
                child: GestureDetector(
                  child: Icon(Icons.edit, color: Colors.white),
                  onTap: () {
                    setState(() {
                      isEditing = true;
                      nameController.text = userProvider.userName ?? '';
                    });
                  },
                ),
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
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0), // 테두리 속성 설정
                borderRadius: BorderRadius.circular(8.0), // 테두리 둥글게 처리
              ),
              padding: EdgeInsets.all(8.0), // 내부 여백 추가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'User Name:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 10,
                  ), // 간격 조절
                  isEditing
                      ? CustomTextField(controller: nameController)
                      : Text(userProvider.userName!,
                          style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.0), // 테두리 속성 설정
                borderRadius: BorderRadius.circular(8.0), // 테두리 둥글게 처리
              ),
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'User Email:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                    height: 10,
                  ),
                  Text(
                    userProvider.userEmail ?? 'Not available',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: mediumGap),
          ],
        ),
      ),
      floatingActionButton: isEditing
          ? FloatingActionButton(
              onPressed: () async {
                await userProvider.setName(nameController.text);
                setState(() => isEditing = false);
              },
              child: Icon(Icons.save),
            )
          : null,
    );
  }
}
