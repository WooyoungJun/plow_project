import 'package:flutter/material.dart';
import 'package:plow_project/size.dart';

import 'components/custom_text_form_field.dart';
import 'components/logo.dart';

class PasswordResetView extends StatefulWidget {
  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final TextEditingController _emailController = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    // final UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 60),
              Logo(),
              SizedBox(height: 30),
              Text(
                'SWeetMe Project 비밀번호 재설정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ), // 비밀번호 재설정 페이지 설명
              SizedBox(height: 30),
              CustomTextFormField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icon(Icons.email),
              ),
              const SizedBox(height: largeGap),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )),
                onPressed: () {}, // 구현 X
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
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
    );
  }
}
