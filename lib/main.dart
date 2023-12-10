import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/HomeView.dart';
import 'package:plow_project/LoginView.dart';
import 'package:plow_project/PasswordResetView.dart';
import 'package:plow_project/SignUpView.dart';
import 'package:provider/provider.dart';

import 'MyInfoView.dart';
import 'firebase_options.dart';

// firebase 초기화 기본 코드
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

// 초기 화면 구성
class MyApp extends StatelessWidget {
  final UserProvider userProvider = UserProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => userProvider,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        initialRoute: '/',
        routes: {
          "/": (context) => AuthenticationWrapper(),
          "/LoginView": (context) => LoginView(),
          "/HomeView": (context) => HomeView(),
          "/SignUpView": (context) => SignUpView(),
          "/PasswordResetView": (context) => PasswordResetView(),
          "/MyInfoView" : (context) => MyInfoView(),
        },
      ),
    );
  }
}

// user 상태에 따라 라우팅 다르게 함
class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
    // userProvider의 상태에 따라 다른 경로로 라우팅
    if (userProvider.user == null) {
      return LoginView(); // 사용자가 로그인하지 않은 경우 로그인 화면으로 이동
    } else {
      return HomeView(); // 사용자가 로그인한 경우 홈으로 이동
    }
  }
}
