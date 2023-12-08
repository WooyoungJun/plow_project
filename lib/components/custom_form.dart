import 'package:flutter/material.dart';
import 'package:plow_project/components/user_provider.dart';

import 'custom_text_form_field.dart';
import 'size.dart';

class CustomForm extends StatefulWidget {
  final UserProvider userProvider; // user 정보 담은 객체
  final TextEditingController emailController; // email 텍스트 컨트롤러
  final TextEditingController passwordController; // password 텍스트 컨트롤러
  final String buttonText; // 버튼 텍스트
  final String route; // 버튼 클릭시 이동할 페이지

  CustomForm({
    super.key,
    required this.userProvider,
    required this.emailController,
    required this.passwordController,
    required this.buttonText,
    required this.route,
  });

  @override
  State<CustomForm> createState() => _CustomFormState(
        userProvider,
        emailController,
        passwordController,
        buttonText,
        route,
      );
}

class _CustomFormState extends State<CustomForm> {
  final UserProvider _userProvider; // user 정보 담은 객체
  final TextEditingController _emailController; // email 텍스트 컨트롤러
  final TextEditingController _passwordController; // password 텍스트 컨트롤러
  final String _buttonText; // 버튼 텍스트
  final String _route; // 버튼 클릭시 이동할 페이지
  String _msg = '';

  _CustomFormState(
    this._userProvider,
    this._emailController,
    this._passwordController,
    this._buttonText,
    this._route,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: _emailController,
          labelText: 'Email',
          icon: Icon(Icons.email),
        ), // 컨트롤러 포함 텍스트 폼 위젯
        const SizedBox(height: mediumGap),
        CustomTextFormField(
          controller: _passwordController,
          labelText: 'Password',
          icon: Icon(Icons.lock),
        ), // 컨트롤러 포함 텍스트 폼 위젯
        const SizedBox(height: largeGap),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(_buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ), // 버튼 텍스트
          onPressed: () async {
            late String result;
            if (_buttonText == 'login') {
              result = await _userProvider.signIn(
                  _emailController.text, _passwordController.text, _buttonText);
            } else if (_buttonText == 'signUp') {
              result = await _userProvider.signUp(
                  _emailController.text, _passwordController.text, _buttonText);
            }

            if (result == '성공') {
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, _route);
            } else {
              setState(() => _msg = result);
            }
          },
        ),
        SizedBox(
          width: 400,
          child: Text(
            _msg,
            style: TextStyle(
              fontSize: 14,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
