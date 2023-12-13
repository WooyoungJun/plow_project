import 'package:flutter/material.dart';
import 'package:plow_project/components/Size.dart';

import '../components/AppBarTitle.dart';
import '../components/CustomTextField.dart';
import '../components/Logo.dart';

class PasswordResetView extends StatefulWidget {
  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final TextEditingController emailController = TextEditingController();
  String msg = '';

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/LoginView'),
        ),
        title: AppBarTitle(title: '비밀번호 찾기').widget,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: xlargeGap),
                Logo(), // 비밀번호 재설정 페이지 설명
                SizedBox(height: largeGap),
                CustomTextField(
                  controller: emailController,
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
      ),
    );
  }
}
