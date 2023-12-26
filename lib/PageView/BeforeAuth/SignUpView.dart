import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:provider/provider.dart';

import '../../components/CustomClass/CustomTextField.dart';
import '../../components/Logo.dart';
import '../../components/const/Size.dart';
import '../../components/UserProvider.dart';

class SignUpView extends StatefulWidget {
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

// 회원 가입 구성
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    emailController.dispose();
    passwordController.dispose();
    print('sign up dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '회원 가입'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: largeGap),
            Logo(),
            SizedBox(height: largeGap),
            Text(
              'SWeetMe Project 회원 가입',
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
              iconData: Icons.email,
            ), // 컨트롤러 포함 텍스트 폼 위젯
            SizedBox(height: largeGap),
            CustomTextField(
              controller: passwordController,
              labelText: 'Password',
              iconData: Icons.lock,
              maxLines: 1,
            ), // 컨트롤러 포함 텍스트 폼 위젯
            SizedBox(height: largeGap),
            ElevatedButton(
              child: Text(
                'Sign Up',
                style: TextStyle(fontSize: 16),
              ), // 버튼 텍스트
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드를 내림
                CustomLoadingDialog.showLoadingDialog(context, '회원가입 중입니다. \n잠시만 기다리세요');
                var result = await userProvider.signUp(
                  emailController.text,
                  passwordController.text,
                  'signUp',
                );
                CustomLoadingDialog.pop(context);
                if (result == '성공') {
                  Navigator.pushNamedAndRemoveUntil(
                    context, '/HomeView',
                    (route) => false, // 모든 스택을 제거하고 '/HomeView'로 이동
                  );
                } else {
                  setState(() => msg = result);
                }
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
