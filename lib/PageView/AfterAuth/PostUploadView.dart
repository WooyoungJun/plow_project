import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/const/Size.dart';

class PostUploadView extends StatefulWidget {
  @override
  State<PostUploadView> createState() => _PostScreenViewState();
}

class _PostScreenViewState extends State<PostUploadView> {
  late UserProvider userProvider;
  late Post post;
  late double contentHeight;
  late int curPage;
  late int vc;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController translateController = TextEditingController();
  bool isTranslate = false;
  bool isSaving = false;
  bool _isInitComplete = false;

  final _picker = ImagePicker();
  String? relativePath;
  String? fileName;
  Uint8List? fileBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initPostUploadView());
  }

  Future<void> initPostUploadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    curPage = argRef['curPage'] as int;
    vc = argRef['vc'] as int;
    post = Post(uid: userProvider.uid!); // 새로운 post 작성
    contentHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        kBottomNavigationBarHeight;
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

    CustomLoadingDialog.showLoadingDialog(context, '업로드 중입니다. 잠시만 기다리세요');
    isSaving = true;
    Map<String, String>? result = await FileProcessing.transitionToStorage(
        relativePath, fileName, fileBytes);
    if (result != null) {
      relativePath = result['relativePath'];
      fileName = result['fileName'];
    }
    Post newPost = Post(
      uid: userProvider.uid!,
      title: titleController.text,
      content: contentController.text,
      translateContent: translateController.text,
      relativePath: relativePath,
      fileName: fileName,
    );
    await PostHandler.addPost(curPage, newPost, vc);
    CustomLoadingDialog.pop(context);
    Navigator.pop(context, {'upload': true});
  }

  Future<void> onBackPressed(BuildContext context) async {
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
                CustomLoadingDialog.showLoadingDialog(
                    context, '취소중입니다. \n잠시만 기다리세요');
                await FileProcessing.deleteFile(relativePath);
                CustomLoadingDialog.pop(context);
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
    if (!_isInitComplete) return CustomProgressIndicator();
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await onBackPressed(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          // Navigator.push로 인한 leading 버튼 없애기
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
                        hintText: userProvider.userName,
                        iconData: Icons.person,
                        isReadOnly: true,
                      ),
                      CustomTextField(
                        controller: titleController,
                        iconData: Icons.title,
                        isReadOnly: false,
                      ), // 제목
                      CustomTextField(
                        controller: contentController,
                        iconData: Icons.description,
                        isReadOnly: false,
                      ), // 본문
                      SizedBox(height: largeGap),
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
                      ), //
                      SizedBox(height: largeGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () async {
                              var result = await FileProcessing.getImage(
                                  _picker, ImageSource.camera);
                              await setResult(result);
                            },
                            icon: Icon(Icons.photo_camera),
                            iconSize: 30.0,
                          ),
                          IconButton(
                            onPressed: () async {
                              var result = await FileProcessing.getFile();
                              await setResult(result);
                            },
                            icon: Icon(Icons.file_open),
                            iconSize: 30.0,
                          ),
                          IconButton(
                            onPressed: () async {
                              CustomLoadingDialog.showLoadingDialog(
                                  context, '텍스트 변환중입니다');
                              String? result = await FileProcessing.fileToText(
                                  relativePath, fileName);
                              CustomLoadingDialog.pop(context);
                              if (result != null) {
                                translateController.text = result;
                                setState(() => isTranslate = true);
                              }
                            },
                            icon: Icon(Icons.g_translate),
                            iconSize: 30.0,
                          )
                        ],
                      ),
                      SizedBox(height: largeGap),
                      CustomTextField(
                        controller: translateController,
                        iconData: Icons.g_translate,
                        isReadOnly: !isTranslate,
                      ), // 작성일
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
