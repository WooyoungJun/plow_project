import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/CustomForm.dart';
import 'components/Logo.dart';
import 'components/UserProvider.dart';

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
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    print('회원가입');
    return Scaffold(
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
                    route: '/home'), // email, password form, 버튼까지(회원가입)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
