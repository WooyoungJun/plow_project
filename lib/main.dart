import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/PageView/AfterAuth/ComparisonView.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:plow_project/firebase_options.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/PageView/AfterAuth/HomeView.dart';
import 'package:plow_project/PageView/BeforeAuth/LoginView.dart';
import 'package:plow_project/PageView/BeforeAuth/PasswordResetView.dart';
import 'package:plow_project/PageView/BeforeAuth/SignUpView.dart';
import 'package:plow_project/PageView/AfterAuth/PostReadView.dart';
import 'package:plow_project/PageView/AfterAuth/PostUploadView.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform); // firebase 초기화 기본 코드
  await FileProcessing.getPublicDownloadFolderPath();
  runApp(MainApp());
}

// 초기 화면 구성
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        initialRoute: '/',
        routes: {
          "/": (context) => SafeArea(child: AuthWrapper()),
          "/LoginView": (context) => SafeArea(child: LoginView()),
          "/HomeView": (context) => SafeArea(child: HomeView()),
          "/SignUpView": (context) => SafeArea(child: SignUpView()),
          "/PasswordResetView": (context) =>
              SafeArea(child: PasswordResetView()),
          "/PostReadView": (context) => SafeArea(child: PostReadView()),
          "/PostUploadView": (context) => SafeArea(child: PostUploadView()),
          "/ComparisonView": (context) => SafeArea(child: ComparisonView()),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return StreamBuilder(
      stream: userProvider.auth.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.data == null) {
          return LoginView();
        } else {
          return HomeView();
        }
      },
    );
  }
}
