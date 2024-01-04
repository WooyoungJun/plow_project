import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/CustomClass/CustomAlertDialog.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

class PostUploadView extends StatefulWidget {
  @override
  State<PostUploadView> createState() => _PostScreenViewState();
}

class _PostScreenViewState extends State<PostUploadView> {
  late UserProvider userProvider;
  late Post newPost;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _translateController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _summarizeController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool isInitComplete = false;
  bool isPdf = false;

  final _picker = ImagePicker();
  String? internalPath;
  Uint8List? fileBytes;
  Uint8List? imageBytes;

  String? firstString;
  String? secondString;
  String? courseResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initPostUploadView());
  }

  Future<void> _initPostUploadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    newPost = Post(uid: userProvider.uid!); // 새로운 post 작성
    setState(() => isInitComplete = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _translateController.dispose();
    _keywordController.dispose();
    _summarizeController.dispose();
    _courseController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _setResult(Map<String, dynamic>? result) async {
    if (result != null) {
      await FileProcessing.deleteFile(relativePath: newPost.relativePath);
      internalPath = result['internalPath'] as String;
      newPost.relativePath = result['relativePath'] as String;
      newPost.fileName = result['fileName'] as String;
      fileBytes = result['fileBytes'] as Uint8List;
      isPdf = newPost.checkPdf();
      _translateController.clear();
      _keywordController.clear();
      _summarizeController.clear();
      _courseController.clear();
      firstString = null;
      setState(() {});
    }
  }

  void setNewPost() {
    newPost.title = _titleController.text;
    newPost.content = _contentController.text;
    newPost.translateContent = _translateController.text;
    newPost.keywordContent = _keywordController.text;
    newPost.summarizeContent = _summarizeController.text;
    newPost.courseContent = _courseController.text;
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitComplete) return CustomProgressIndicator();
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await CustomAlertDialog.onBackPressed(
            context: context, relativePath: newPost.relativePath);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          title: AppBarTitle(title: '자유 게시판'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            GestureDetector(
              child: Icon(Icons.save, color: Colors.white),
              onTap: () async {
                setNewPost();
                await CustomAlertDialog.onSavePressed(
                  context: context,
                  post: null,
                  newPost: newPost,
                  fileBytes: fileBytes,
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async => await CustomAlertDialog.onBackPressed(
                  context: context, relativePath: newPost.relativePath),
            )
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return RawScrollbar(
              thumbColor: Colors.grey,
              thickness: 8,
              radius: Radius.circular(6),
              padding: EdgeInsets.only(right: 4.0),
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: ConstSet.screenHeight),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CustomTextField(
                          showText: userProvider.userName,
                          prefixIcon: Icon(Icons.person),
                          isReadOnly: true,
                          maxLines: 1,
                        ),
                        CustomTextField(
                          controller: _titleController,
                          prefixIcon: Icon(Icons.title),
                          isReadOnly: false,
                        ),
                        CustomTextField(
                          controller: _contentController,
                          prefixIcon: Icon(Icons.description),
                          isReadOnly: false,
                        ),
                        SizedBox(height: ConstSet.mediumGap),
                        fileBytes != null ? pdfOrImgView() : Text('이미지가 없습니다'),
                        SizedBox(height: ConstSet.mediumGap),
                        fileSelect(),
                        SizedBox(height: ConstSet.largeGap),
                        CustomTextField(
                          controller: _translateController,
                          prefixIcon: Icon(Icons.g_translate),
                          isReadOnly: true,
                          maxLines: 1,
                        ),
                        firstString != null
                            ? ElevatedButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, '/ComparisonView',
                                    arguments: {
                                      'fileBytes': fileBytes,
                                      'original': firstString,
                                      'first': firstString,
                                      'second': secondString ?? '',
                                    }),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.difference),
                                    SizedBox(width: ConstSet.mediumGap),
                                    Text('변환 결과 확인하기',
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              )
                            : Container(),
                        CustomTextField(
                          controller: _keywordController,
                          prefixIcon: Icon(Icons.key),
                          isReadOnly: true,
                          maxLines: 1,
                        ),
                        CustomTextField(
                          controller: _summarizeController,
                          prefixIcon: Icon(Icons.summarize),
                          isReadOnly: true,
                          maxLines: 1,
                        ),
                        CustomTextField(
                          controller: _courseController,
                          prefixIcon: Icon(Icons.search),
                          isReadOnly: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget pdfOrImgView() {
    return isPdf
        ? Column(
            children: [
              SizedBox(
                height: 300,
                child: SfPdfViewer.memory(
                  fileBytes!,
                  scrollDirection: PdfScrollDirection.vertical,
                ),
              ),
              pdfToImgButton(),
            ],
          )
        : SizedBox(
            height: 300,
            child: ListView(
              children: [
                Image.memory(fileBytes!, fit: BoxFit.cover),
              ],
            ),
          );
  }

  Widget pdfToImgButton() {
    return ElevatedButton(
      onPressed: () async {
        Map<String, dynamic>? result =
            await CustomAlertDialog.onPdfToPngPressed(
          context: context,
          relativePath: newPost.relativePath!,
          fileBytes: fileBytes!,
        );
        if (result == null) return;
        await _setResult(result);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.transform),
          SizedBox(width: ConstSet.mediumGap),
          Text('pdf를 이미지로 변환하기', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget fileSelect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            var result = await FileProcessing.getImage(picker: _picker);
            await _setResult(result);
          },
          icon: Icon(Icons.photo_camera),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            var result = await FileProcessing.getFile();
            await _setResult(result);
          },
          icon: Icon(Icons.file_open),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            if (validateCheck()) return;
            bool isCheck = await CustomAlertDialog.show(
                context: context, text: '이미지로부터 텍스트를 추출하시겠습니까?');
            if (!isCheck) return;
            CustomLoadingDialog.showLoadingDialog(context, '텍스트 변환중입니다');
            RecognizedText? result = await FileProcessing.inputFileToText(
              textRecognizer: _textRecognizer,
              internalPath: internalPath,
            );
            String? storageResult = await FileProcessing.storageFileToText(
              relativePath: newPost.relativePath!,
              fileName: newPost.fileName!,
            );
            CustomLoadingDialog.pop(context);
            if (result != null) {
              firstString = result.text;
              secondString = storageResult;
              _translateController.text = result.text;
              setState(() {});
            }
          },
          icon: Icon(Icons.g_translate),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            if (validateCheck()) return;
            bool isCheck = await CustomAlertDialog.show(
                context: context, text: '키워드 텍스트를 추출하시겠습니까?');
            if (!isCheck) return;
            CustomLoadingDialog.showLoadingDialog(context, '키워드 텍스트를 추출중입니다.');
            String? result = await FileProcessing.keyExtraction(
                extractedText: _translateController.text);
            CustomLoadingDialog.pop(context);
            if (result != null) {
              _keywordController.text = result;
              setState(() {});
            }
          },
          icon: Icon(Icons.key),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            if (validateCheck()) return;
            bool isCheck = await CustomAlertDialog.show(
                context: context, text: '텍스트를 요약하시겠습니까?');
            if (!isCheck) return;
            CustomLoadingDialog.showLoadingDialog(context, '텍스트를 요약중입니다.');
            String? result = await FileProcessing.makeSummary(
              text: firstString!,
              keywords: _keywordController.text,
            );
            CustomLoadingDialog.pop(context);
            if (result != null) {
              _summarizeController.text = result;
              print(result);
              setState(() {});
            } else {
              print('실패');
            }
          },
          icon: Icon(Icons.summarize),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            if (validateCheck()) return;
            bool isCheck = await CustomAlertDialog.show(
                context: context, text: '강의를 검색하시겠습니까?');
            if (!isCheck) return;
            CustomLoadingDialog.showLoadingDialog(context, '강의를 검색중입니다.');
            String? result = await FileProcessing.searchCourse(
              keyword: _keywordController.text,
            );
            CustomLoadingDialog.pop(context);
            if (result != null) {
              _courseController.text = result;
              print(result);
              setState(() {});
            }
          },
          icon: Icon(Icons.search),
          iconSize: 30.0,
        ),
      ],
    );
  }

  bool validateCheck() {
    if (fileBytes != null && !isPdf) return false;
    if (fileBytes == null) CustomToast.showToast('파일을 선택하세요');
    if (isPdf) CustomToast.showToast('이미지로 변환해주세요');
    return true;
  }
}
