import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';
import '../../components/CustomClass/CustomDrawer.dart';
import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomToast.dart';
import '../../components/PostHandler.dart';
import '../../components/FileProcessing.dart';
import '../../components/const/Size.dart';

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late int index;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  bool isEditing = false;
  bool isUpdate = false;
  bool isUpload = false;

  final _picker = ImagePicker();
  File? _pickedFile;
  String? _fileExtension;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    post = argRef['post'] as Post;
    index = argRef['index'] as int;
    titleController.text = post.title;
    contentController.text = post.content;
    // 끝나고 build 호출
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    titleController.dispose();
    contentController.dispose();
    // print('post screen dispose');
    super.dispose();
  }

  Future<void> _handleSaveButton() async {
    if (titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }
    if ((post.title != titleController.text) ||
        (post.content != contentController.text) ||
        (_pickedFile != null)) {
      Post updatedPost = Post(
        postId: post.postId,
        uid: userProvider.uid!,
        title: titleController.text,
        content: contentController.text,
        createdDate: post.createdDate,
        relativePath: post.relativePath,
      );
      if (_pickedFile != null) {
        // 업로드 후 relativePath 업데이트
        Map<String, String>? result =
            await FileProcessing.uploadFile(_pickedFile, _fileExtension);
        if (result != null) {
          updatedPost.relativePath = result['relativePath'];
          updatedPost.downloadURL = result['downloadURL'];
        }
      }
      await PostHandler.updatePost('BoardList', updatedPost); // post 업데이트
      post = updatedPost;
      isUpdate = true;
    } else {
      CustomToast.showToast('변경 사항이 없습니다!');
    }
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> _showDeleteCheck(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('정말 삭제하시겠습니까?', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          // content: Text('정말 삭제하시겠습니까?'),
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
                    // 확인 버튼이 눌렸을 때, 게시물 삭제 수행
                    await PostHandler.deletePost(
                        'BoardList', post.postId, post.relativePath);
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.pop(context, {'isUpdate': true});
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          Visibility(
            visible: (post.uid == userProvider.uid),
            // 작성자 id와 같아야 함
            child: GestureDetector(
              child: isEditing
                  ? Icon(
                      Icons.save,
                      color: Colors.white,
                    )
                  : Icon(Icons.edit, color: Colors.white),
              onTap: () {
                setState(() {
                  if (isEditing) {
                    _handleSaveButton();
                  } else {
                    isEditing = !isEditing;
                  }
                });
              },
            ),
          ), // 수정하기 버튼
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () =>
                Navigator.pop(context, {'isUpdate': isUpdate, 'post': post}),
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
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CustomTextField(
                hintText: userProvider.userName,
                icon: Icon(Icons.person),
                isReadOnly: true,
              ),
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
                hintText: post.createdDate,
                icon: Icon(Icons.calendar_month),
                isReadOnly: true,
              ),
              SizedBox(height: largeGap),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: FileProcessing.imageOrText(
                    pickedFile: _pickedFile, downloadURL: post.downloadURL),
              ), // 작성일
              isEditing
                  ? Column(
                      children: [
                        SizedBox(height: largeGap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                var result = await FileProcessing.getImage(
                                    _picker, ImageSource.gallery);
                                if (result != null) {
                                  _pickedFile = result['pickedFile'] as File;
                                  _fileExtension =
                                      result['fileExtension'] as String;
                                  setState(() {});
                                }
                              },
                              child: Text('갤러리에서 이미지 선택'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                var result = await FileProcessing.getImage(
                                    _picker, ImageSource.camera);
                                if (result != null) {
                                  _fileExtension =
                                      result['fileExtension'] as String;
                                  _pickedFile = result['pickedFile'] as File;
                                  setState(() {});
                                }
                              },
                              child: Text('카메라로 촬영하기'),
                            ),
                          ],
                        ),
                        SizedBox(height: largeGap),
                        ElevatedButton(
                          onPressed: () async {
                            await FileProcessing.fileToText(post.relativePath);
                          },
                          child: Text('텍스트 변환'),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
      floatingActionButton: !isEditing
          ? FloatingActionButton(
              onPressed: () => _showDeleteCheck(context),
              child: Icon(
                Icons.delete,
                color: Colors.red,
              ),
            )
          : null,
    );
  }
}
