import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/custom_form.dart';
import 'components/logo.dart';
import 'components/user_provider.dart';

class SignUpView extends StatefulWidget {
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

// 회원 가입 구성
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String msg = '';

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    print('회원가입');
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
                'SWeetMe Project 회원 가입',
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
                  buttonText: 'signUp',
                  route: '/login'), // email, password form, 버튼까지(회원가입)
            ],
          ),
        ),
      ),
    );
  }
}
