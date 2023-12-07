// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/custom_form.dart';
import 'components/logo.dart';
import 'components/user_provider.dart';

class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

// 로그인, 로그아웃 구성
class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    print('로그인 로그아웃');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 모든 공간 채우기
            children: [
              SizedBox(height: 60),
              Logo(),
              SizedBox(height: 30),
              Text(
                'SWeetMe Project 로그인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ), // 페이지 설명
              SizedBox(height: 30),
              CustomForm(
                  userProvider: userProvider,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  buttonText: 'login',
                  route: '/home'), // email, password form, 버튼까지(로그인)
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reset_password'),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ), // password 재 설정(미구현)
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signUp');
                    },
                    child: Text('Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
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
