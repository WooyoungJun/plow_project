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

  final Map<Type, TextEditingController> _controller = {
    Type.title: TextEditingController(),
    Type.content: TextEditingController(),
    Type.translate: TextEditingController(),
    Type.keyword: TextEditingController(),
    Type.summarize: TextEditingController(),
    Type.course: TextEditingController(),
  };
  final Set<Type> targetKey = {
    Type.translate,
    Type.keyword,
    Type.summarize,
    Type.course
  };

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool isInitComplete = false;
  bool isPdf = false;

  final _picker = ImagePicker();
  String? internalPath;
  Uint8List? fileBytes;
  Uint8List? imageBytes;

  final Map<Type, List<String>> _resultAll = {
    Type.translate: ['', ''],
    Type.keyword: ['', ''],
    Type.summarize: ['', ''],
    Type.course: ['', ''],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initPostUploadView());
  }

  Future<void> _initPostUploadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    newPost = Post(uid: userProvider.uid); // 새로운 post 작성
    setState(() => isInitComplete = true);
  }

  @override
  void dispose() {
    for (var entry in _controller.entries) {
      entry.value.dispose();
    }
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

      for (var entry in _controller.entries) {
        if (targetKey.contains(entry.key)) {
          entry.value.clear();
          _resultAll[entry.key] = ['', ''];
        }
      }
      setState(() {});
    }
  }

  void _setNewPost() {
    newPost.title = _controller[Type.title]!.text;
    newPost.content = _controller[Type.content]!.text;
    newPost.translateContent = _controller[Type.translate]!.text;
    newPost.keywordContent = _controller[Type.keyword]!.text;
    newPost.summarizeContent = _controller[Type.summarize]!.text;
    newPost.courseContent = _controller[Type.course]!.text;
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
                _setNewPost();
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
                          controller: _controller[Type.title],
                          prefixIcon: Icon(Icons.title),
                          isReadOnly: false,
                        ),
                        CustomTextField(
                          controller: _controller[Type.content],
                          prefixIcon: Icon(Icons.description),
                          isReadOnly: false,
                        ),
                        SizedBox(height: ConstSet.mediumGap),
                        fileBytes != null ? pdfOrImgView() : Text('이미지가 없습니다'),
                        SizedBox(height: ConstSet.mediumGap),
                        fileSelect(),
                        SizedBox(height: ConstSet.largeGap),
                        contentBlock(
                          type: Type.translate,
                          prefixIcon: Icon(Icons.g_translate),
                        ),
                        contentBlock(
                          type: Type.keyword,
                          prefixIcon: Icon(Icons.key),
                        ),
                        contentBlock(
                          type: Type.summarize,
                          prefixIcon: Icon(Icons.summarize),
                        ),
                        CustomTextField(
                          controller: _controller[Type.course]!,
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

  Widget contentBlock({
    required Icon prefixIcon,
    required Type type,
  }) {
    return Column(
      children: [
        CustomTextField(
          controller: _controller[type]!,
          prefixIcon: prefixIcon,
          isReadOnly: true,
          maxLines: 1,
        ),
        _resultAll[type]![0] != ''
            ? ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/ComparisonView', arguments: {
                  'fileBytes': fileBytes,
                  'original': _resultAll[type]![0],
                  'first': _resultAll[type]![0],
                  'second': _resultAll[type]![1],
                }),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.difference),
                    SizedBox(width: ConstSet.mediumGap),
                    Text('변환 결과 확인하기', textAlign: TextAlign.center),
                  ],
                ),
              )
            : Container(),
      ],
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
        customIconButton(
          icon: Icon(Icons.g_translate),
          alertText: '이미지로부터 텍스트를 추출하시겠습니까?',
          loadingText: '텍스트 변환중입니다',
          doTask: () async {
            RecognizedText? result1 = await FileProcessing.inputFileToText(
              textRecognizer: _textRecognizer,
              internalPath: internalPath,
            );
            String? result2 = await FileProcessing.storageFileToText(
              relativePath: newPost.relativePath!,
              fileName: newPost.fileName!,
            );
            return {'first': result1?.text, 'second': result2};
          },
          type: Type.translate,
        ),
        customIconButton(
          icon: Icon(Icons.key),
          alertText: '키워드 텍스트를 추출하시겠습니까?',
          loadingText: '키워드 텍스트를 추출중입니다.',
          doTask: () async {
            String? result1 = await FileProcessing.keyExtraction(
                extractedText: _resultAll[Type.translate]![0]);
            String? result2 = await FileProcessing.keyExtraction(
                extractedText: _resultAll[Type.translate]![1]);
            return {'first': result1, 'second': result2};
          },
          type: Type.keyword,
        ),
        customIconButton(
          icon: Icon(Icons.summarize),
          alertText: '텍스트를 요약하시겠습니까?',
          loadingText: '텍스트를 요약중입니다.',
          doTask: () async {
            String? result1 = await FileProcessing.makeSummary(
              text: _resultAll[Type.translate]![0],
              keywords: _resultAll[Type.keyword]![0],
            );
            String? result2 = await FileProcessing.makeSummary(
              text: _resultAll[Type.translate]![1],
              keywords: _resultAll[Type.keyword]![1],
            );
            return {'first': result1, 'second': result2};
          },
          type: Type.summarize,
        ),
        customIconButton(
          icon: Icon(Icons.search),
          alertText: '강의를 검색하시겠습니까?',
          loadingText: '강의를 검색중입니다.',
          doTask: () async {
            String? result = await FileProcessing.searchCourse(
              keyword: _resultAll[Type.translate]![0],
            );
            return {'first': result};
          },
          type: Type.course,
        ),
      ],
    );
  }

  Widget customIconButton({
    required Icon icon,
    required String alertText,
    required String loadingText,
    required Function doTask,
    required Type type,
  }) {
    return IconButton(
      onPressed: () async {
        if (validateCheck()) return;
        bool isCheck =
            await CustomAlertDialog.show(context: context, text: alertText);
        if (!isCheck) return;
        CustomLoadingDialog.showLoadingDialog(context, loadingText);
        Map<String, dynamic> result = await doTask();
        CustomLoadingDialog.pop(context);
        if (result['first'] != null) {
          _controller[type]!.text = result['first'];
          _resultAll[type] = [result['first'], result['second'] ?? ''];
          setState(() {});
        }
      },
      icon: icon,
      iconSize: 30.0,
    );
  }

  bool validateCheck() {
    if (fileBytes != null && !isPdf) return false;
    if (fileBytes == null) CustomToast.showToast('파일을 선택하세요');
    if (isPdf) CustomToast.showToast('이미지로 변환해주세요');
    return true;
  }
}
