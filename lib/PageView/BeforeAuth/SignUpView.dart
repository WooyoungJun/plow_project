import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/Logo.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomTextStyle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';

class SignUpView extends StatefulWidget {
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

// 회원 가입 구성
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late UserProvider userProvider;
  late String msg;
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initSignUpView());
  }

  Future<void> initSignUpView() async {
    msg = '';
    userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isInitComplete = true);
  }

  // context 접근 가능
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: AppBarTitle(title: '회원 가입'),
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
              'SWeetMe Project 회원 가입',
              textAlign: TextAlign.center,
              style: CustomTextStyle.style(24),
            ),
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              prefixIcon: Icon(Icons.email, size: 15.0),
              maxLines: 1,
            ),
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _passwordController,
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              maxLines: 1,
              suffixIconData: Icons.visibility,
            ),
            SizedBox(height: ConstSet.largeGap),
            ElevatedButton(
              child: Text('Sign Up'),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                CustomLoadingDialog.showLoadingDialog(
                    context, '회원가입 중입니다. \n잠시만 기다리세요');
                var result = await userProvider.signUp(
                  email: _emailController.text,
                  password: _passwordController.text,
                );
                CustomLoadingDialog.pop(context);
                if (result == '성공') {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/HomeView', (route) => false);
                } else {
                  setState(() => msg = result);
                }
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
