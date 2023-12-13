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
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pushReplacementNamed(context, '/HomeView'),
        // ),
        title: AppBarTitle(title: '나의 정보').widget,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          )
        ],
      ),
      endDrawer: CustomDrawer(
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
                      ? CustomTextField(controller: nameController).widget
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
            Visibility(
              visible: !isEditing,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isEditing = true;
                      nameController.text = userProvider.userName ?? '';
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text(
                        '수정하기',
                        style: TextStyle(
                            // 텍스트 스타일 설정 (예: 폰트 크기, 색상 등)
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ), // 수정하기 버튼
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
