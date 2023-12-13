import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:provider/provider.dart';

import '../components/CustomTextField.dart';
import '../components/Logo.dart';
import '../components/Size.dart';
import '../components/UserProvider.dart';

class SignUpView extends StatefulWidget {
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

// 회원 가입 구성
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String msg = '';

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    print('회원가입');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/LoginView'),
        ),
        title: AppBarTitle(title: '회원 가입').widget,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // 모든 공간 채우기
              children: [
                SizedBox(height: xlargeGap),
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
                  icon: Icon(Icons.email),
                ).widget, // 컨트롤러 포함 텍스트 폼 위젯
                SizedBox(height: largeGap),
                CustomTextField(
                  controller: passwordController,
                  labelText: 'Password',
                  icon: Icon(Icons.lock),
                ).widget, // 컨트롤러 포함 텍스트 폼 위젯
                SizedBox(height: largeGap),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      textStyle: TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('signUp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                  ), // 버튼 텍스트
                  onPressed: () async {
                    var result = await userProvider.signUp(
                      emailController.text,
                      passwordController.text,
                      'signUp',
                    );
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
                  width: 400,
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
      ),
    );
  }
}
