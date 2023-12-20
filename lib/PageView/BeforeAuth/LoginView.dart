import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomTextField.dart';
import '../../components/Logo.dart';
import '../../components/const/Size.dart';
import '../../components/UserProvider.dart';

class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

// 로그인, 로그아웃 구성
class _LoginViewState extends State<LoginView> {
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
    print('login dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '로그인'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 화면 가운데 정렬
            children: [
              SizedBox(height: largeGap),
              Logo(),
              SizedBox(height: largeGap),
              Text(
                'SWeetMe Project 로그인',
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
              ), // 컨트롤러 포함 텍스트 폼 위젯
              SizedBox(height: largeGap),
              CustomTextField(
                controller: passwordController,
                labelText: 'Password',
                icon: Icon(Icons.lock),
                maxLines: 1,
              ), // 컨트롤러 포함 텍스트 폼 위젯
              SizedBox(height: largeGap),
              ElevatedButton(
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 16),
                ), // 버튼 텍스트
                onPressed: () async {
                  var result = await userProvider.signIn(
                    emailController.text,
                    passwordController.text,
                    'Login',
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
                child: Text(
                  msg,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: largeGap),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/PasswordResetView'),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ), // password 재 설정(미구현)
              SizedBox(height: largeGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don\'t have an account?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/SignUpView'),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ), // 회원 가입 버튼(signUp 페이지)
            ],
          ),
        ),
      ),
    );
  }
}