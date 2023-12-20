import 'package:flutter/material.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';

import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomTextField.dart';
import '../../components/Logo.dart';
import '../../components/UserProvider.dart';

class PasswordResetView extends StatefulWidget {
  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final TextEditingController emailController = TextEditingController();
  late UserProvider userProvider;
  late String msg;

  // init -> didChangeDependencies -> build 호출
  @override
  void initState() {
    super.initState();
    msg = ''; // 메세지 초기화
  }

  // context 접근 가능
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    emailController.dispose();
    print('reset password dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '비밀번호 찾기'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: largeGap),
              Logo(), // 비밀번호 재설정 페이지 설명
              SizedBox(height: largeGap),
              Text(
                'SWeetMe Project 비밀번호 변경',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ), // 페이지 설명
              SizedBox(height: largeGap),
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                icon: Icon(Icons.email),
              ),
              SizedBox(height: largeGap),
              ElevatedButton(
                child: Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 16),
                ), // 버튼 텍스트
                onPressed: () async {
                  userProvider.resetPassword(emailController.text);
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
      ),
    );
  }
}
