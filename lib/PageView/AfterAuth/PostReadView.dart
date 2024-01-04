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

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late Post newPost;
  late String userName;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _translateController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _summarizeController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool _isInitComplete = false;
  bool isPdf = false;
  bool isEditing = false;

  final _picker = ImagePicker();
  String? internalPath;
  Uint8List? fileBytes;

  String? firstTranslate;
  String? secondTranslate;
  String? firstKeyword;
  String? secondKeyword;
  String? firstSummarize;
  String? secondSummarize;
  String? courseResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initPostReadView());
  }

  Future<void> _initPostReadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    post = argRef['post'] as Post;
    newPost = Post.copy(post);
    userName = (await UserProvider.getUserName(newPost.uid))!;
    fileBytes = await FileProcessing.loadFileFromStorage(
        relativePath: newPost.relativePath);
    if (newPost.fileName != null) isPdf = newPost.checkPdf();
    setState(() => _isInitComplete = true);
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
      firstTranslate = null;
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
    if (!_isInitComplete) return CustomProgressIndicator();
    return PopScope(
      canPop: !isEditing,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await CustomAlertDialog.onBackPressed(
            context: context,
            relativePath: post.relativePath == newPost.relativePath
                ? null
                : newPost.relativePath);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
          title: AppBarTitle(title: '자유 게시판'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            Visibility(
              visible: (newPost.uid == userProvider.uid),
              child: GestureDetector(
                child: isEditing
                    ? Icon(Icons.save, color: Colors.white)
                    : Icon(Icons.edit, color: Colors.white),
                onTap: () async {
                  if (isEditing) {
                    setNewPost();
                    await CustomAlertDialog.onSavePressed(
                      context: context,
                      post: post,
                      newPost: newPost,
                      fileBytes: fileBytes,
                    );
                  }
                  setState(() => isEditing = !isEditing);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                isEditing
                    ? await CustomAlertDialog.onBackPressed(
                        context: context,
                        relativePath: post.relativePath == newPost.relativePath
                            ? null
                            : newPost.relativePath)
                    : Navigator.pop(context);
              },
            )
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
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
                        showText: userName,
                        prefixIcon: Icon(Icons.person),
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      CustomTextField(
                        controller: _titleController,
                        showText: newPost.title,
                        prefixIcon: Icon(Icons.title),
                        isReadOnly: !isEditing,
                      ),
                      CustomTextField(
                        controller: _contentController,
                        showText: newPost.content,
                        prefixIcon: Icon(Icons.description),
                        isReadOnly: !isEditing,
                      ),
                      CustomTextField(
                        showText: newPost.modifyDate ?? newPost.createdDate,
                        prefixIcon: Icon(Icons.calendar_month),
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      SizedBox(height: ConstSet.mediumGap),
                      fileBytes != null ? pdfOrImgView() : Text('이미지가 없습니다'),
                      SizedBox(height: ConstSet.mediumGap),
                      isEditing ? fileSelect() : Container(),
                      CustomTextField(
                        controller: _translateController,
                        showText: newPost.translateContent,
                        prefixIcon: Icon(Icons.g_translate),
                        suffixIconData: Icons.difference,
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      firstTranslate != null
                          ? ElevatedButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/ComparisonView',
                                  arguments: {
                                    'fileBytes': fileBytes,
                                    'original': firstTranslate,
                                    'first': firstTranslate,
                                    'second': secondTranslate ?? '',
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
                        showText: newPost.keywordContent,
                        prefixIcon: Icon(Icons.key),
                        isReadOnly: true,
                      ),
                      firstKeyword != null
                          ? ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/ComparisonView',
                            arguments: {
                              'fileBytes': fileBytes,
                              'original': firstKeyword,
                              'first': firstKeyword,
                              'second': secondKeyword ?? '',
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
                        controller: _summarizeController,
                        showText: newPost.summarizeContent,
                        prefixIcon: Icon(Icons.summarize),
                        isReadOnly: true,
                      ),
                      firstSummarize != null
                          ? ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/ComparisonView',
                            arguments: {
                              'fileBytes': fileBytes,
                              'original': firstSummarize,
                              'first': firstSummarize,
                              'second': secondSummarize ?? '',
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
                        controller: _courseController,
                        showText: newPost.courseContent,
                        prefixIcon: Icon(Icons.search),
                        isReadOnly: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        floatingActionButton: !isEditing && newPost.uid == userProvider.uid
            ? FloatingActionButton(
                onPressed: () async => await CustomAlertDialog.onDeletePressed(
                    context: context, post: newPost),
                child: Icon(Icons.delete, color: Colors.red),
              )
            : null,
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
      mainAxisAlignment: MainAxisAlignment.center,
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
            if (internalPath == null) {
              return CustomToast.showToast('파일을 새롭게 업로드 한 뒤 시도해주세요');
            }
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
              firstTranslate = result.text;
              secondTranslate = storageResult;
              // secondTranslate = '';
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
            String? result1 = await FileProcessing.keyExtraction(
                extractedText: firstTranslate ?? '');
            String? result2 = await FileProcessing.keyExtraction(
                extractedText: secondTranslate ?? '');
            CustomLoadingDialog.pop(context);
            if (result1 != null) {
              _keywordController.text = result1;
              firstKeyword = result1;
              secondKeyword = result2;
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
            String? result1 = await FileProcessing.makeSummary(
              text: firstTranslate ?? '',
              keywords: firstKeyword ?? '',
            );
            String? result2 = await FileProcessing.makeSummary(
              text: secondTranslate ?? '',
              keywords: secondKeyword ?? '',
            );
            CustomLoadingDialog.pop(context);
            if (result1 != null) {
              _summarizeController.text = result1;
              firstSummarize = result1;
              secondSummarize = result2;
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
            } else {
              print('실패');
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
    // if (internalPath == null) CustomToast.showToast('파일을 새롭게 업로드 한 뒤 시도해주세요');
    return true;
  }
}
