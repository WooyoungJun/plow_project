import 'package:flutter/material.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/Logo.dart';
import 'package:plow_project/components/UserProvider.dart';

class PasswordResetView extends StatefulWidget {
  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final TextEditingController _emailController = TextEditingController();
  late UserProvider userProvider;
  late String msg;

  @override
  void initState() {
    super.initState();
    msg = ''; // 메세지 초기화
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initPasswordResetView());
  }

  Future<void> initPasswordResetView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  // context 접근 가능
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '비밀번호 찾기'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: ConstSet.largeGap),
            Logo(), // 비밀번호 재설정 페이지 설명
            SizedBox(height: ConstSet.largeGap),
            Text(
              'SWeetMe Project 비밀번호 변경',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ), // 페이지 설명
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _emailController,
              fontSize: 16.0,
              labelText: 'Email',
              iconData: Icons.email,
              maxLines: 1,
            ),
            SizedBox(height: ConstSet.largeGap),
            ElevatedButton(
              child: Text('Reset Password'), // 버튼 텍스트
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드를 내림
                CustomLoadingDialog.showLoadingDialog(
                    context, '비밀번호 변경중입니다. \n잠시만 기다리세요');
                await userProvider.resetPassword(_emailController.text);
                CustomLoadingDialog.pop(context);
                Navigator.pushReplacementNamed(context, '/LoginView');
              },
            ),
            SizedBox(
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
