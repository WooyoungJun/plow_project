import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomAlertDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

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

  Future<void> initHomeViewFriendManage() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.getStatus();
    setState(() => _isInitComplete = true);
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
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '친구 관리'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              await userProvider.getStatus();
              setState(() {});
            },
          )
        ],
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
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('추가하고자 하는 친구의 이메일을 입력하세요'),
                    SizedBox(height: ConstSet.mediumGap),
                    CustomTextField(controller: _emailController),
                    SizedBox(height: ConstSet.largeGap),
                    ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus(); // 키보드를 내림
                        if (_emailController.text.isEmpty) {
                          return CustomToast.showToast('친구 이메일을 입력하세요');
                        }
                        await CustomAlertDialog.showFriendCheck(
                            context: context,
                            userProvider: userProvider,
                            text: '추가',
                            controller: _emailController);
                        setState(() {});
                      },
                      child: Text('친구 추가 버튼'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ConstSet.largeGap),
            Expanded(child: friend()),
          ],
        ),
      ),
    );
  }

  Widget friend() {
    List<String> friend = userProvider.friend;
    return Container(
      alignment: Alignment.center,
      child: friend.length == 1
          ? Text("친구가 없습니다.")
          : ListView.builder(
              itemCount: friend.length - 1,
              itemExtent: ConstSet.itemHeight,
              itemBuilder: (context, index) => friendRow(friend[index + 1]),
            ),
    );
  }

  Widget friendRow(String friendEmail) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: ConstSet.smallGap),
          Text(friendEmail, style: TextStyle(fontSize: 16)),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              await CustomAlertDialog.showFriendCheck(
                  context: context,
                  userProvider: userProvider,
                  text: '삭제',
                  friendEmail: friendEmail);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
