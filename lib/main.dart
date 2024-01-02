import 'package:flutter/material.dart';
import 'package:plow_project/PageView/AfterAuth/ComparisonView.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:plow_project/firebase_options.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
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
  runApp(MyApp());
}

// 초기 화면 구성
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UserProvider userProvider = UserProvider();
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initMain());
  }

  Future<void> _initMain() async {
    // ConstSet.openApiKey = await PostHandler.openApiKey;
    await FileProcessing.getPublicDownloadFolderPath();
    setState(() => _isInitComplete = true);
  }

  @override
  void dispose() {
    userProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
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
          "/": (context) => SafeArea(child: AuthenticationWrapper()),
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

// user 상태에 따라 라우팅 다르게 함
class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    if (userProvider.uid == null) {
      return LoginView(); // 사용자가 로그인하지 않은 경우 로그인 화면으로 이동
    } else {
      return HomeView(); // 사용자가 로그인한 경우 홈으로 이동
    }
  }
}
