import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomAlertDialog.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

class HomeViewMyInfo extends StatefulWidget {
  const HomeViewMyInfo({super.key});

  @override
  State<HomeViewMyInfo> createState() => _HomeViewMyInfoState();
}

class _HomeViewMyInfoState extends State<HomeViewMyInfo> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _creditController = TextEditingController();
  late UserProvider userProvider;
  bool _isInitComplete = false;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeViewMyInfo());
  }

  Future<void> initHomeViewMyInfo() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.userName;
    _creditController.text = userProvider.credit.toString();
    await userProvider.getStatus();
    setState(() => _isInitComplete = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '나의 정보 관리'),
        centerTitle: true,
        actions: [
          Row(
            children: [
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    isEditing ? Icons.save : Icons.edit,
                    color: Colors.white,
                  ),
                ),
                onTap: () async {
                  if (!isEditing) return setState(() => isEditing = !isEditing);
                  String name = _nameController.text;
                  if (name.trim().isEmpty) {
                    return CustomToast.showToast('이름을 입력하세요');
                  }
                  bool isCheck = await CustomAlertDialog.show(
                      context: context, text: '이름을 변경하시겠습니까?');
                  if (!isCheck) return; // 취소했으면 그냥 유지
                  CustomLoadingDialog.showLoadingDialog(context, '이름을 변경중입니다.');
                  await userProvider.setName(_nameController.text);
                  CustomLoadingDialog.pop(context);
                  setState(() => isEditing = !isEditing);
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(userProvider.icon, size: 120),
              ),
            ),
            Divider(
              color: Colors.grey,
              thickness: 4,
              indent: 20,
              endIndent: 20,
              height: 20,
            ),
            Expanded(child: myInfo()),
            Expanded(child: quest()),
            SizedBox(height: ConstSet.largeGap),
            IntrinsicWidth(
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: ConstSet.mediumGap),
                    Text('로그아웃', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () async {
                  bool isSignOut = await CustomAlertDialog.show(
                      context: context, text: '정말 로그아웃 하시겠습니까?');
                  if (isSignOut) {
                    await userProvider.signOut();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/LoginView', (route) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget myInfo() {
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        CustomTextField(
          controller: _nameController,
          prefixIcon: Icon(Icons.verified_user),
          isReadOnly: !isEditing,
        ),
        CustomTextField(
          showText: userProvider.uid,
          prefixIcon: Icon(Icons.email),
          isReadOnly: true,
        ),
        CustomTextField(
          showText: userProvider.count.toString(),
          prefixIcon: Icon(Icons.numbers),
          isReadOnly: true,
        ),
        CustomTextField(
          controller: _creditController,
          prefixIcon: Icon(Icons.money),
          isReadOnly: true,
        ),
        // for (MapEntry<String, dynamic> value in userQuestStatus.entries)
        //   CustomTextField(
        //     showText: '${value.key} ${value.value}',
        //     isReadOnly: true,
        //   ),
      ],
    );
  }

  Widget quest() {
    Map<String, dynamic> userQuestStatus = userProvider.dailyQuestStatus;
    bool getCredit = userProvider.canGetCredit();
    return ListView(
      scrollDirection: Axis.vertical,
      children: [
        CheckboxListTile(
          title: Text(
            '3개의 포스트 작성하기 \n(현재 게시글 수: ${userQuestStatus['postCount']})',
            textAlign: TextAlign.center,
          ),
          value: userQuestStatus['postCount'] >= 3,
          onChanged: (bool? value) {},
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              await userProvider.resetDailyQuests();
              setState(() {});
            },
            child: Text('퀘스트 초기화'),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: getCredit
                ? () async {
                    await userProvider.getCredit();
                    _creditController.text = userProvider.credit.toString();
                    setState(() {});
                  }
                : null,
            child: Text('크레딧 받기!'),
          ),
        ),
      ],
    );
  }
}
