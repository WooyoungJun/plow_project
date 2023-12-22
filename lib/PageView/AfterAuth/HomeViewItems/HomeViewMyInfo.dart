import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/const/Size.dart';

class HomeViewMyInfo extends StatefulWidget {
  const HomeViewMyInfo({super.key});

  @override
  State<HomeViewMyInfo> createState() => _HomeViewMyInfoState();
}

class _HomeViewMyInfoState extends State<HomeViewMyInfo> {
  final TextEditingController nameController = TextEditingController();
  late UserProvider userProvider;
  bool _isInitComplete = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeViewMyInfo());
  }

  // 초기 설정
  // userProvider -> 사용자 정보
  // inInitComplete -> ProgressIndicator 띄울 수 있도록 초기화 상태 체크
  Future<void> initHomeViewMyInfo() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    nameController.text = userProvider.userName;
    setState(() => _isInitComplete = true);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: '나의 정보'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Row(
            children: [
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(10.0), // 아이콘 주변의 간격 조절
                  child: Icon(isEditing ? Icons.save : Icons.edit,
                      color: Colors.white),
                ),
                onTap: () async {
                  if (isEditing) {
                    CustomLoadingDialog.showLoadingDialog(
                        context, '이름을 변경중입니다.');
                    await userProvider.setName(nameController.text);
                    CustomLoadingDialog.pop(context);
                  }
                  setState(() => isEditing = !isEditing);
                },
              ), // 수정하기 버튼
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                  radius: 60, child: Icon(Icons.account_circle, size: 120)),
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
            SizedBox(height: 20), // 로그아웃 버튼과 다른 위젯 간의 간격 조절
            ListTile(
              title: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Icon(Icons.exit_to_app, color: Colors.red),
                  ),
                  SizedBox(width: largeGap),
                  Text('로그아웃', style: TextStyle(color: Colors.red)),
                ],
              ),
              contentPadding: EdgeInsets.only(bottom: 4.0),
              onTap: () {
                userProvider.signOut('signOut');
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
