import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';

import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomDrawer.dart';
import '../../components/CustomClass/CustomToast.dart';
import '../../components/PostHandler.dart';
import '../../components/const/Size.dart';

class PostUploadView extends StatefulWidget {
  @override
  State<PostUploadView> createState() => _PostScreenViewState();
}

class _PostScreenViewState extends State<PostUploadView> {
  late UserProvider userProvider;
  late Post post;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController translateController = TextEditingController();
  bool isTranslate = false;
  bool isBackPressed = false;
  bool isSaving = false;

  final _picker = ImagePicker();
  String? relativePath;
  String? fileName;
  Uint8List? fileBytes;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context);
    post = Post(uid: userProvider.uid!); // 새로운 post 작성
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void setResult(Map<String, dynamic>? result) {
    if (result != null) {
      relativePath = result['relativePath'];
      fileName = result['fileName'];
      fileBytes = result['fileBytes'];
      translateController.clear();
      setState(() {});
    }
  }

  @override
  void dispose() {
    // 페이지가 dispose 될 때 controller를 dispose 해줍니다.
    titleController.dispose();
    contentController.dispose();
    translateController.dispose();
    // print('post upload dispose');
    super.dispose();
  }

  Future<void> _handleSaveButton(BuildContext context) async {
    if (isSaving) {
      return CustomToast.showToast("처리중입니다");
    }
    if (titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }
    isSaving = true;
    if (relativePath != null) {
      Map<String, dynamic>? result =
          await FileProcessing.transitionToStorage(relativePath!, fileName!);
      if (result != null) {
        post.relativePath = result['relativePath'];
        post.fileName = result['fileName'];
      }
    }
    Post newPost = Post(
      uid: userProvider.uid!,
      title: titleController.text,
      content: contentController.text,
      translateContent: translateController.text,
      relativePath: relativePath,
      fileName: fileName,
    );
    newPost = await PostHandler.addPost('BoardList', newPost);
    Navigator.pop(context, {'post': newPost});
  }

  Future<void> onBackPressed(BuildContext context) async {
    if (isBackPressed) {
      return CustomToast.showToast("처리중입니다");
    }
    isBackPressed = true;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('정말 뒤로 가시겠습니까?'),
                Text('저장하지 않은 정보가 삭제될 수 있습니다.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                    context, '/HomeView'); // 그냥 홈으로 이동
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        await onBackPressed(context);
      },
      child: Scaffold(
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
            GestureDetector(
              child: Icon(
                Icons.save,
                color: Colors.white,
              ),
              onTap: () async => await _handleSaveButton(context),
            ), // 포스트 업로드
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async => await onBackPressed(context),
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
                  isReadOnly: false,
                ), // 제목
                CustomTextField(
                  controller: contentController,
                  icon: Icon(Icons.description),
                  isReadOnly: false,
                ), // 본문
                SizedBox(height: largeGap),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: fileBytes != null
                      ? Image.memory(fileBytes!, fit: BoxFit.cover)
                      : Text('이미지가 없습니다'),
                ), //
                SizedBox(height: largeGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          var result = await FileProcessing.getImage(
                              _picker, ImageSource.gallery);
                          setResult(result);
                        },
                        child: Text(
                          '갤러리에서 \n이미지 선택',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          var result = await FileProcessing.getImage(
                              _picker, ImageSource.camera);
                          setResult(result);
                        },
                        child: Text(
                          '카메라로 \n촬영하기',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          var result = await FileProcessing.getFile();
                          setResult(result);
                        },
                        child: Text(
                          '파일 \n선택하기',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    String? result =
                        await FileProcessing.fileToText(relativePath);
                    if (result != null) {
                      translateController.text = result;
                      setState(() => isTranslate = true);
                    }
                  },
                  child: Text('텍스트 변환'),
                ),
                CustomTextField(
                  controller: translateController,
                  icon: Icon(Icons.g_translate),
                  isReadOnly: !isTranslate,
                ), // 작성일
              ],
            ),
          ),
        ),
      ),
    );
  }
}
