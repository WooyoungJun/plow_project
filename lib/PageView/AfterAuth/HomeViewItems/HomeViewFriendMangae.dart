import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';

class HomeViewFriendManage extends StatefulWidget {
  @override
  State<HomeViewFriendManage> createState() => _HomeViewFriendManageState();
}

class _HomeViewFriendManageState extends State<HomeViewFriendManage> {
  late UserProvider userProvider;
  final TextEditingController _emailController = TextEditingController();
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeViewFriendManage());
  }

  // 초기 설정
  // userProvider -> 사용자 정보
  // inInitComplete -> ProgressIndicator 띄울 수 있도록 초기화 상태 체크
  Future<void> initHomeViewFriendManage() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isInitComplete = true);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: '친구 추가하기'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '추가하고자 하는 친구의 이메일을 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await userProvider.addFriend(_emailController.text);
                FocusScope.of(context).unfocus(); // 키보드를 내림
              },
              child: Text('친구 추가 버튼'),
            ),
          ],
        ),
      ),
    );
  }
}
