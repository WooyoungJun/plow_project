import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

class HomeViewMyInfo extends StatefulWidget {
  const HomeViewMyInfo({super.key});

  @override
  State<HomeViewMyInfo> createState() => _HomeViewMyInfoState();
}

class _HomeViewMyInfoState extends State<HomeViewMyInfo> {
  final TextEditingController _nameController = TextEditingController();
  late UserProvider userProvider;
  late int count;
  bool _isInitComplete = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeViewMyInfo());
  }

  Future<void> initHomeViewMyInfo() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.userName;
    count = await PostHandler.myTotalPostCount(email: userProvider.userEmail);
    setState(() => _isInitComplete = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '나의 정보 관리'),
        centerTitle: true,
        actions: [
          Row(
            children: [
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    isEditing ? Icons.save : Icons.edit,
                    color: Colors.white,
                  ),
                ),
                onTap: () async {
                  if (isEditing) {
                    String name = _nameController.text;
                    if (name.trim().isEmpty)
                      return CustomToast.showToast('이름을 입력하세요');
                    CustomLoadingDialog.showLoadingDialog(
                        context, '이름을 변경중입니다.');
                    await userProvider.setName(_nameController.text);
                    CustomLoadingDialog.pop(context);
                  }
                  setState(() => isEditing = !isEditing);
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(userProvider.icon, size: 120),
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
              controller: _nameController,
              icon: Icon(Icons.badge, size: 25.0),
              isReadOnly: !isEditing,
            ),
            CustomTextField(
              hintText: userProvider.userEmail,
              icon: Icon(Icons.email, size: 25.0),
              isReadOnly: true,
            ),
            CustomTextField(
              hintText: '$count',
              icon: Icon(Icons.numbers_rounded, size: 20.0),
              isReadOnly: true,
            ),
            SizedBox(height: ConstSet.largeGap), // 로그아웃 버튼과 다른 위젯 간의 간격 조절
            ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Icon(Icons.exit_to_app, color: Colors.red),
                  ),
                  SizedBox(width: ConstSet.largeGap),
                  Text('로그아웃', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () {
                userProvider.signOut();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/LoginView', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
