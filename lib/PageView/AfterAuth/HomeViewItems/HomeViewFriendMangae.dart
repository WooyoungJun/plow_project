import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';

class HomeViewFriendManage extends StatefulWidget {
  @override
  State<HomeViewFriendManage> createState() => _HomeViewFriendManageState();
}

class _HomeViewFriendManageState extends State<HomeViewFriendManage> {
  late UserProvider userProvider;
  final TextEditingController _emailController1 = TextEditingController();
  final TextEditingController _emailController2 = TextEditingController();
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
    _emailController1.dispose();
    _emailController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        leading: Container(), // Navigator.push로 인한 leading 버튼 없애기
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '친구 추가하기'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController1,
              decoration: InputDecoration(
                labelText: '추가하고자 하는 친구의 이메일을 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: largeGap),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드를 내림
                await userProvider.addFriend(_emailController1.text);
                _emailController1.clear();
              },
              child: Text('친구 추가 버튼'),
            ),
            SizedBox(height: largeGap),
            TextField(
              controller: _emailController2,
              decoration: InputDecoration(
                labelText: '삭제하고자 하는 친구의 이메일을 입력하세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: largeGap),
            ElevatedButton(
              onPressed: () async {
                FocusScope.of(context).unfocus(); // 키보드를 내림
                await userProvider.deleteFriend(_emailController2.text);
                _emailController2.clear();
              },
              child: Text('친구 삭제 버튼'),
            ),
          ],
        ),
      ),
    );
  }
}
