import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/Logo.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomTextStyle.dart';

class PasswordResetView extends StatefulWidget {
  @override
  State<PasswordResetView> createState() => _PasswordResetViewState();
}

class _PasswordResetViewState extends State<PasswordResetView> {
  final TextEditingController _emailController = TextEditingController();
  String msg = '';
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initPasswordResetView());
  }

  Future<void> initPasswordResetView() async {
    setState(() => _isInitComplete = true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '비밀번호 찾기'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: ConstSet.largeGap),
            Logo(),
            SizedBox(height: ConstSet.largeGap),
            Text(
              'SWeetMe Project 비밀번호 변경',
              textAlign: TextAlign.center,
              style: CustomTextStyle.style(24),
            ),
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              maxLines: 1,
            ),
            SizedBox(height: ConstSet.largeGap),
            ElevatedButton(
              child: Text('Reset Password'),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                CustomLoadingDialog.showLoadingDialog(
                    context, '비밀번호 변경중입니다. \n잠시만 기다리세요');
                await userProvider.resetPassword(email: _emailController.text);
                CustomLoadingDialog.pop(context);
                Navigator.pushReplacementNamed(context, '/LoginView');
              },
            ),
            SizedBox(height: ConstSet.largeGap),
            SizedBox(
              child: Text(
                msg,
                style: TextStyle(
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
