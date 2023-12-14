import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plow_project/components/CustomDrawer.dart';
import 'package:plow_project/components/CustomTextField.dart';
import 'package:provider/provider.dart';

import '../components/AppBarTitle.dart';
import '../components/DataHandler.dart';
import '../components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late UserProvider _userProvider;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();

    // build 이후에 실행시킬 부분
    // (build에서 async 직접 사용하긴 힘듦)
    WidgetsBinding.instance.addPostFrameCallback((_) => getData());
  }

  // 사용자 uid로 POST 가져오기
  Future<void> getData() async {
    posts = await DataInFireStore.readPost('BoardList', _userProvider.uid!);
    setState(() {});
  }

  // 추가 or 수정하기 tab
  Future<void> onAddOrUpdateTab(
      {Post? post,
      int? index,
      required bool isAdd,
      required String uid}) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    // 수정 하기
    if (!isAdd) {
      titleController.text = post!.title;
      contentController.text = post.content;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAdd ? '추가하기' : '수정하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: titleController,
                labelText: 'Title',
                icon: Icon(Icons.title),
              ),
              CustomTextField(
                controller: contentController,
                labelText: 'content',
                icon: Icon(Icons.description),
              ),
            ],
          ), // title, content 수정
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소하기'),
            ), // 취소하기 버튼
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return showToast('제목은 비어질 수 없습니다');
                }
                if (isAdd) {
                  DateTime koreaTime =
                      DateTime.now().toUtc().add(Duration(hours: 9));
                  // 날짜 및 시간 포맷 지정
                  String formattedTime =
                      DateFormat.yMd().add_jms().format(koreaTime);
                  Post newPost = Post(
                      postId: '',
                      uid: _userProvider.uid!,
                      title: titleController.text,
                      content: contentController.text,
                      createdDate: formattedTime);
                  newPost = await DataInFireStore.addPost(
                      'BoardList', newPost, _userProvider.uid!);
                  setState(() => posts.add(newPost));
                  Navigator.of(context).pop();
                } else {
                  if (!(post!.title == titleController.text &&
                      post.content == contentController.text)) {
                    Post updatedPost = Post(
                      postId: post.postId,
                      uid: _userProvider.uid!,
                      title: titleController.text,
                      content: contentController.text,
                      createdDate: post.createdDate,
                    );
                    await DataInFireStore.updatePost('BoardList', updatedPost);
                    setState(() => posts[index!] = updatedPost);
                    Navigator.of(context).pop();
                  } else {
                    return showToast('변경 사항이 없습니다!');
                  }
                }
              },
              child: Text(isAdd ? '추가하기' : "수정하기"),
            ),
          ],
        );
      },
    );
  }

  // 하단 메뉴를 표시하는 함수
  Future<void> _showBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 작성 후 뒤돌아왔을 때 BottomSheet 없애기 위해 pop
                  Navigator.pushNamed(
                      context, '/PhotoUploadView'); // 게시글 작성으로 넘어가기
                },
                child: Text('사진 업로드하기'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAddOrUpdateTab(isAdd: true, uid: _userProvider.uid!);
                },
                child: Text('게시글 작성하기'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '자유 게시판'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: CustomDrawer(
        userProvider: _userProvider,
        drawerItems: [
          DrawerItem(
              icon: Icons.person,
              color: Colors.blue,
              text: '나의 정보',
              route: '/MyInfoView'),
          DrawerItem(
              icon: Icons.exit_to_app,
              color: Colors.red,
              text: '로그아웃',
              route: '/LoginView'),
        ],
      ),
      body: ListView.builder(
        shrinkWrap: true, // 길이 맞게 위젯 축소 허용
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, '/PostScreenView',
                arguments: post),
            child: Container(
              margin: EdgeInsets.only(left: 8, right: 8, top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(post.title),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
