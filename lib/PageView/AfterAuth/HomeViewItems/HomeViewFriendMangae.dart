import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:provider/provider.dart';

class HomeViewFriendManage extends StatefulWidget {
  @override
  State<HomeViewFriendManage> createState() => _HomeViewFriendManageState();
}

class _HomeViewFriendManageState extends State<HomeViewFriendManage> {
  late UserProvider userProvider;
  final TextEditingController _emailController1 = TextEditingController();
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
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('추가하고자 하는 친구의 이메일을 입력하세요'),
                    CustomTextField(controller: _emailController1),
                    SizedBox(height: ConstSet.mediumGap),
                    ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // 키보드를 내림
                        _showFriendCheck(
                            context: context,
                            text: '추가',
                            controller: _emailController1);
                      },
                      child: Text('친구 추가 버튼'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ConstSet.largeGap),
            friend(),
          ],
        ),
      ),
    );
  }

  Future<void> _showFriendCheck(
      {required BuildContext context,
      required String text,
      TextEditingController? controller,
      String? friendEmail}) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('정말 $text하시겠습니까?', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('확인'),
                  onPressed: () async {
                    CustomLoadingDialog.showLoadingDialog(
                        context, '$text중입니다. \n잠시만 기다리세요');
                    if (text == '삭제') {
                      await userProvider.deleteFriend(friendEmail!);
                    } else {
                      await userProvider.addFriend(controller!.text);
                      controller.clear();
                    }
                    await userProvider.getFriend();
                    CustomLoadingDialog.pop(context);
                    Navigator.pop(context); // 다이얼로그 닫기
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget friend() {
    List<String> friend = userProvider.friend;
    return Container(
      alignment: Alignment.center,
      child: friend.length == 1
          ? Text("친구가 없습니다.")
          : Column(
              children: [
                for (int i = 1; i < friend.length; i++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        friend[i],
                        style: TextStyle(fontSize: 15.0),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _showFriendCheck(
                            context: context,
                            text: '삭제',
                            friendEmail: friend[i]),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
