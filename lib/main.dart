import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // svg 이미지 렌더링
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// firebase 초기화 기본 코드
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// 초기 화면 구성
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: Consumer<UserProvider>(
          builder: (context, user, child) => LoginView(),
        ),
      ),
    );
  }
}

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

// FirebaseAuth, status(로그인 상태), User객체 가지고 있음
class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  Status _status;
  User? _user;

  Status get status => _status;

  User? get user => _user;

  // user 생성자
  UserProvider()
      : _auth = FirebaseAuth.instance,
        _user = FirebaseAuth.instance.currentUser,
        _status = FirebaseAuth.instance.currentUser != null
            ? Status.authenticated
            : Status.unauthenticated {
    // 사용자 정보 변경시 이벤트 발생 메소드 -> 해당 event listen
    _auth.authStateChanges().listen(_onStateChanged);
  }

  Future<void> _onStateChanged(User? user) async {
    if (user == null) {
      _status = Status.unauthenticated;
    } else {
      _status = Status.authenticated;
      _user = user;
    }
    notifyListeners();
    // 사용자 정보 변경 시 해당 코드 실행
    // -> Consumer 코드 다시 실행 되면서 화면 다시 build
  }

  Future<String> signUp(String email, String password) async {
    try {
      // _status = Status.authenticating;
      // notifyListeners();
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return '성공';
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return e.message!;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signIn(String email, String password) async {
    try {
      // _status = Status.authenticating;
      // notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return '성공';
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return e.message!;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _status = Status.unauthenticated;
    notifyListeners();
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

// 로그인 시 나오는 화면
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    print('Home ${userProvider.user?.email}'); // user email 출력
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Screen"),
        actions: [
          ElevatedButton.icon(
            icon: Icon(Icons.logout),
            label: Text("Logout"),
            onPressed: () async {
              await userProvider.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Welcome, ${userProvider.user?.email ?? 'Anonymous'}",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// 로그인, 로그아웃 구성
class _LoginViewState extends State<LoginView> {
  // TextField와 연동된 Controller 객체 가져오기 -> 텍스트 컨트롤 가능
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    print('로그인 로그아웃');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 모든 공간 채우기
            children: [
              SizedBox(height: 60),
              SizedBox(
                height: 100,
                width: 100,
                child: SvgPicture.asset(
                  'assets/images/wave.svg',
                  fit: BoxFit.contain,
                ),
              ), // 로고 이미지
              SizedBox(height: 30),
              Text('SWeetme Project',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )), // 프로젝트 설명
              SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
              ), // _emailController 연동
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true, // password 화면에 안보이게
                decoration: InputDecoration(
                  labelText: 'Password',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ), // _passwordController 연동
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )),
                onPressed: () async {
                  String result = await userProvider.signIn(
                      _emailController.text, _passwordController.text);

                  if (!mounted) return;

                  if (result == '성공') {
                    print('로그인 성공');
                    Navigator.pushReplacement(
                      // 페이지 삭제 후 Home으로 넘어감
                      context,
                      MaterialPageRoute(builder: (context) => HomeView()),
                    );
                  } else {
                    setState(() => msg = result);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                ),
              ), // 로그인 버튼(singIn 호출)
              SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ), // password 찾기 기능(미구현)
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      )),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpView()));
                    },
                    child: Text('Sign Up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ),
                ],
              ), // 회원 가입 버튼(signUp 페이지)
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

// 회원 가입 구성
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    print('회원가입');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 모든 공간 채우기
            children: [
              SizedBox(height: 60),
              SizedBox(
                height: 100,
                width: 100,
                child: SvgPicture.asset(
                  'assets/images/wave.svg',
                  fit: BoxFit.contain,
                ),
              ), // 로고 이미지
              SizedBox(height: 30),
              Text('SWeetme Project SignUp Page',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )), // 프로젝트 설명
              SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
              ), // _emailController 연동
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true, // password 화면에 안보이게
                decoration: InputDecoration(
                  labelText: 'Password',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ), // _passwordController 연동
              SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  String result = await userProvider.signUp(
                      _emailController.text, _passwordController.text);
                  // 위젯이 마운트되지 않으면 context에 아무것도 없을 수 있음
                  if (!mounted) return;

                  if (result == '성공') {
                    print('회원 가입 성공');
                    Navigator.pushReplacement(
                      // 페이지 삭제 후 Login으로 넘어감
                      context,
                      MaterialPageRoute(builder: (context) => LoginView()),
                    );
                  } else {
                    setState(() => msg = result);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ), // 회원 가입 버튼(singUp 호출)
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
