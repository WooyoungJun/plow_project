import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomTextStyle.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/Logo.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late UserProvider userProvider;
  late String msg;
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initLoginView());
  }

  Future<void> initLoginView() async {
    msg = '';
    userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isInitComplete = true);
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
        title: AppBarTitle(title: '로그인'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: false, // 키보드로 인한 오버플로우 방지
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 화면 가운데 정렬
          children: [
            SizedBox(height: ConstSet.largeGap),
            Logo(),
            SizedBox(height: ConstSet.largeGap),
            Text(
              'SWeetMe Project 로그인',
              textAlign: TextAlign.center,
              style: CustomTextStyle.style(24),
            ),
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              icon: Icon(Icons.email),
              maxLines: 1,
            ),
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _passwordController,
              labelText: 'Password',
              icon: Icon(Icons.lock),
              maxLines: 1,
            ),
            SizedBox(height: ConstSet.largeGap),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                CustomLoadingDialog.showLoadingDialog(
                    context, '로그인 중입니다. \n잠시만 기다리세요');
                String result = await userProvider.signIn(
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
            Text(
              msg,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 3,
            ),
            SizedBox(height: ConstSet.largeGap),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/PasswordResetView'),
              child: Text('Forgot Password?', style: CustomTextStyle.style(18)),
            ),
            SizedBox(height: ConstSet.largeGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account?', style: CustomTextStyle.style(16)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/SignUpView'),
                  child: Text('Sign Up', style: CustomTextStyle.style(18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
