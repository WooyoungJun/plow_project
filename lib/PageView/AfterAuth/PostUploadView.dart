import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';
import '../../components/CustomClass/CustomDrawer.dart';
import '../../components/AppBarTitle.dart';
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

  final _picker = ImagePicker();
  File? _pickedFile;
  String? _fileExtension;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    post = Post(uid: userProvider.uid!); // 새로운 post 작성
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
    // print('post upload dispose');
    super.dispose();
  }

  Future<void> _handleSaveButton(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }
    Post newPost = Post(
      uid: userProvider.uid!,
      title: titleController.text,
      content: contentController.text,
    );
    if (_pickedFile != null) {
      // 업로드 후 relativePath 업데이트
      Map<String, String>? result =
      await FileProcessing.uploadFile(_pickedFile, _fileExtension);
      if (result != null) {
        newPost.relativePath = result['relativePath'];
        newPost.downloadURL = result['downloadURL'];
      }
    }
    newPost = await PostHandler.addPost('BoardList', newPost);
    Navigator.pop(context, {'post': newPost});
  }

  @override
  Widget build(BuildContext context) {
    print('build');
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
          GestureDetector(
            child: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onTap: () => _handleSaveButton(context),
          ), // 포스트 업로드
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
              CustomTextField(
                hintText: post.createdDate,
                icon: Icon(Icons.calendar_month),
                isReadOnly: true,
              ), // 작성일
              SizedBox(height: largeGap),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: FileProcessing.imageOrText(
                    pickedFile: _pickedFile, downloadURL: post.downloadURL),
              ), //
              SizedBox(height: largeGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      var result = await FileProcessing.getImage(
                          _picker, ImageSource.gallery);
                      if (result != null) {
                        _fileExtension = result['fileExtension'] as String;
                        _pickedFile = result['pickedFile'] as File;
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
                        _fileExtension = result['fileExtension'] as String;
                        _pickedFile = result['pickedFile'] as File;
                        setState(() {});
                      }
                    },
                    child: Text('카메라로 촬영하기'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FileProcessing.fileToText(post.relativePath);
                },
                child: Text('텍스트 변환'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
