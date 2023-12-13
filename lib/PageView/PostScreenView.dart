import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';
import '../components/AppBarTitle.dart';
import '../components/CustomDrawer.dart';
import '../components/DataHandler.dart';

class PostScreenView extends StatefulWidget {
  @override
  State<PostScreenView> createState() => _PostScreenViewState();
}

class _PostScreenViewState extends State<PostScreenView> {
  late UserProvider userProvider;
  late Post post;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController createdController = TextEditingController();
  bool isEditing = false;

  Future<void> _handleSaveButton() async {
    if (titleController.text.trim().isEmpty) {
      return showToast('제목은 비어질 수 없습니다');
    }
    if (!(post.title == titleController.text &&
        post.content == contentController.text)) {
      Post updatedPost = Post(
        postId: post.postId,
        uid: userProvider.uid!,
        title: titleController.text,
        content: contentController.text,
        createdDate: post.createdDate,
      );
      await DataInFireStore.updatePost('BoardList', updatedPost);
    } else {
      showToast('변경 사항이 없습니다!');
    }
    setState(() {
      post.title = titleController.text;
      post.content = contentController.text;
      isEditing = !isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);
    var postRef = ModalRoute.of(context)?.settings.arguments as Post?;
    // var isAdd = ModalRoute.of(context)?.settings.arguments as bool?;
    if (postRef == null) {
      // 새로운 post 작성
      post = Post(uid: userProvider.uid!);
      isEditing = true;
    } else {
      // post 존재 시 출력
      post = postRef;
      titleController.text = post.title;
      contentController.text = post.content;
      createdController.text = post.createdDate;
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '게시글 읽기'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Visibility(
            visible: (!isEditing && post.uid == userProvider.uid),
            // 작성자 id와 같아야 함
            child: GestureDetector(
              child: Icon(Icons.edit, color: Colors.white),
              onTap: () {
                setState(() => isEditing = !isEditing);
              },
            ),
          ), // 수정하기 버튼
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      drawer: CustomDrawer(
        userProvider: userProvider,
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CustomTextField(
              controller: titleController,
              icon: Icon(Icons.title),
              isReadOnly: !isEditing,
            ), // 제목
            CustomTextField(
              controller: contentController,
              icon: Icon(Icons.description),
              isReadOnly: !isEditing,
            ), // 본문
            CustomTextField(
              controller: createdController,
              icon: Icon(Icons.calendar_month),
              isReadOnly: true,
            ), // 작성일
          ],
        ),
      ),
      floatingActionButton: isEditing
          ? FloatingActionButton(
              onPressed: () => _handleSaveButton(), child: Icon(Icons.save))
          : null,
    );
  }
}
