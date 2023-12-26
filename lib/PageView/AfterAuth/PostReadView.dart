import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/const/Size.dart';

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late double contentHeight;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController translateController = TextEditingController();
  bool isEditing = false;
  bool _isInitComplete = false;

  final _picker = ImagePicker();
  String? relativePath;
  String? fileName;
  Uint8List? fileBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initPostReadView());
  }

  // 초기 설정
  // userProvider -> 사용자 정보
  // Home에서 가져온 post 정보 기반으로 title, content, 변환Text, 이미지 읽어오기
  // inInitComplete -> ProgressIndicator 띄울 수 있도록 초기화 상태 체크
  Future<void> initPostReadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, Post>;
    post = argRef['post']!;
    titleController.text = post.title;
    contentController.text = post.content;
    translateController.text = post.translateContent ?? '';
    fileBytes = await FileProcessing.loadFileFromStorage(post.relativePath);
    contentHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        kBottomNavigationBarHeight;

    setState(() => _isInitComplete = true);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> setResult(Map<String, dynamic>? result) async {
    if (result != null) {
      await FileProcessing.deleteFile(relativePath);
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
    // print('post screen dispose');
    super.dispose();
  }

  Future<void> _handleSaveButton() async {
    if (titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }
    if ((post.title != titleController.text) ||
        (post.content != contentController.text) ||
        (relativePath != null) ||
        (translateController.text != post.translateContent)) {
      CustomLoadingDialog.showLoadingDialog(context, '업로드 중입니다. \n잠시만 기다리세요');
      Post updatedPost = Post(
        postId: post.postId,
        uid: userProvider.uid!,
        title: titleController.text,
        content: contentController.text,
        createdDate: post.createdDate,
        translateContent: translateController.text,
        relativePath: post.relativePath,
        fileName: post.fileName,
      );
      Map<String, String>? result = await FileProcessing.transitionToStorage(
          relativePath, fileName, fileBytes);
      if (result != null) {
        FileProcessing.deleteFile(post.relativePath);
        updatedPost.relativePath = result['relativePath'];
        updatedPost.fileName = result['fileName'];
      }
      await PostHandler.updatePost('BoardList', updatedPost); // post 업데이트
      post = updatedPost;
      CustomLoadingDialog.pop(context);
      Navigator.pop(context, {'post': updatedPost});
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
                    CustomLoadingDialog.showLoadingDialog(
                        context, '삭제중입니다. \n잠시만 기다리세요');
                    await FileProcessing.deleteFile(post.relativePath);
                    await PostHandler.deletePost('BoardList', post.postId);
                    CustomLoadingDialog.pop(context);
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(context, {'post': null});
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
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        // Navigator.push로 인한 leading 버튼 없애기
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
                if (isEditing) {
                  _handleSaveButton();
                } else {
                  setState(() => isEditing = !isEditing);
                }
              },
            ),
          ), // 수정하기 버튼
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, {'post': post}),
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contentHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: post.uid,
                      iconData: Icons.person,
                      iconSize: 10.0,
                      isReadOnly: true,
                    ),
                    CustomTextField(
                      controller: titleController,
                      iconData: Icons.title,
                      iconSize: 10.0,
                      isReadOnly: !isEditing,
                    ), // 제목
                    CustomTextField(
                      controller: contentController,
                      iconData: Icons.description,
                      iconSize: 10.0,
                      isReadOnly: !isEditing,
                    ), // 본문
                    CustomTextField(
                      hintText: post.modifyDate ?? post.createdDate,
                      iconData: Icons.calendar_month,
                      iconSize: 10.0,
                      isReadOnly: true,
                    ),
                    SizedBox(height: mediumGap),
                    Flexible(
                      child: fileBytes != null
                          ? ((fileName ?? post.fileName!).endsWith('.pdf')
                              ? PDFView(
                                  pdfData: fileBytes!,
                                  enableSwipe: true,
                                  swipeHorizontal: true,
                                  autoSpacing: false,
                                  pageFling: false,
                                  fitPolicy: FitPolicy.BOTH,
                                )
                              : Image.memory(fileBytes!, fit: BoxFit.cover))
                          : Text('이미지가 없습니다'),
                    ),
                    if (isEditing)
                      Column(
                        children: [
                          SizedBox(height: largeGap),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      var result =
                                          await FileProcessing.getImage(
                                              _picker, ImageSource.camera);
                                      await setResult(result);
                                    },
                                    icon: Icon(Icons.photo_camera),
                                    iconSize: 30.0,
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      var result =
                                          await FileProcessing.getFile();
                                      await setResult(result);
                                    },
                                    icon: Icon(Icons.file_open),
                                    iconSize: 30.0,
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      CustomLoadingDialog.showLoadingDialog(
                                          context, '텍스트 변환중입니다');
                                      String? result =
                                          await FileProcessing.fileToText(
                                              relativePath ?? post.relativePath,
                                              fileName ?? post.fileName);
                                      CustomLoadingDialog.pop(context);
                                      if (result != null) {
                                        translateController.text = result;
                                        setState(() {});
                                      }
                                    },
                                    icon: Icon(Icons.g_translate),
                                    iconSize: 30.0,
                                  )
                                ],
                              ),
                              SizedBox(height: largeGap),
                            ],
                          )
                        ],
                      )
                    else
                      Container(),
                    CustomTextField(
                      maxLines: 10,
                      controller: translateController,
                      iconData: Icons.g_translate,
                      iconSize: 10.0,
                      isReadOnly: !isEditing,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      floatingActionButton: !isEditing && post.uid == userProvider.uid
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
