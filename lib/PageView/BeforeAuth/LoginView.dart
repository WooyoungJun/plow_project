import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/Logo.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/UserProvider.dart';

class LoginView extends StatefulWidget {
  @override
  State<LoginView> createState() => _LoginViewState();
}

// 로그인, 로그아웃 구성
class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late UserProvider userProvider;
  late String msg;

  @override
  void initState() {
    super.initState();
    msg = '';
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initLoginView());
  }

  Future<void> initLoginView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ), // 페이지 설명
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _emailController,
              fontSize: 16.0,
              labelText: 'Email',
              iconData: Icons.email,
              maxLines: 1,
            ), // 컨트롤러 포함 텍스트 폼 위젯
            SizedBox(height: ConstSet.largeGap),
            CustomTextField(
              controller: _passwordController,
              fontSize: 16.0,
              labelText: 'Password',
              iconData: Icons.lock,
              maxLines: 1,
            ), // 컨트롤러 포함 텍스트 폼 위젯
            SizedBox(height: ConstSet.largeGap),
            ElevatedButton(
              child: Text('Login'), // 버튼 텍스트
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드를 내림
                CustomLoadingDialog.showLoadingDialog(
                    context, '로그인 중입니다. \n잠시만 기다리세요');
                var result = await userProvider.signIn(
                  _emailController.text,
                  _passwordController.text,
                  'Login',
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
            SizedBox(
              child: Text(
                msg,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: ConstSet.largeGap),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/PasswordResetView'),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: ConstSet.largeGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/SignUpView'),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ), // 회원 가입 버튼(signUp 페이지)
          ],
        ),
      ),
    );
  }
}
