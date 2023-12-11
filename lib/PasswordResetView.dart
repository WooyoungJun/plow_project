import 'package:flutter/material.dart';
import 'package:plow_project/components/Size.dart';

import 'components/CustomTextField.dart';
import 'components/Logo.dart';

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
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: xlargeGap),
                  Logo(),
                  SizedBox(height: largeGap),
                  Text(
                    'SWeetMe Project 비밀번호 재설정',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ), // 비밀번호 재설정 페이지 설명
                  SizedBox(height: largeGap),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    icon: Icon(Icons.email),
                  ).widget,
                  SizedBox(height: largeGap),
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
        ));
  }
}
