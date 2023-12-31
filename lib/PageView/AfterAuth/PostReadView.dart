import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomAlertDialog.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/ConstSet.dart';

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late Post newPost;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _translateController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool _isInitComplete = false;
  bool isPdf = false;
  bool isEditing = false;
  bool isSearch = false;

  final _picker = ImagePicker();
  String? internalPath;
  String? relativePath;
  String? fileName;
  Uint8List? fileBytes;
  RecognizedText? recognizedText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initPostReadView());
  }

  // 초기 설정
  // userProvider -> 사용자 정보
  // Home에서 가져온 post 정보 기반으로 title, content, 변환Text, 이미지 읽어오기
  // inInitComplete -> ProgressIndicator 띄울 수 있도록 초기화 상태 체크
  Future<void> _initPostReadView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    post = argRef['post'] as Post;
    newPost = Post.copy(post);
    _titleController.text = newPost.title;
    _contentController.text = newPost.content;
    _translateController.text = newPost.translateContent;
    _keywordController.text = newPost.keywordContent;
    fileBytes = await FileProcessing.loadFileFromStorage(
        relativePath: newPost.relativePath);
    isPdf = newPost.checkPdf(isPdf: isPdf, anotherFileName: fileName);
    setState(() => _isInitComplete = true);
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _translateController.dispose();
    _keywordController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _setResult(Map<String, dynamic>? result) async {
    if (result != null) {
      await FileProcessing.deleteFile(relativePath: relativePath);
      internalPath = result['internalPath'] as String;
      relativePath = result['relativePath'] as String;
      fileName = result['fileName'] as String;
      fileBytes = result['fileBytes'] as Uint8List;
      isPdf = newPost.checkPdf(isPdf: isPdf, anotherFileName: fileName);
      _translateController.clear();
      setState(() {});
    }
  }

  void setNewPost() {
    newPost.title = _titleController.text;
    newPost.content = _contentController.text;
    newPost.translateContent = _translateController.text;
    newPost.keywordContent = _keywordController.text;
    if (relativePath == null) return;
    newPost.relativePath = relativePath; // 갱신
    newPost.fileName = fileName;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        await CustomAlertDialog.onBackPressed(context, relativePath);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
          // Navigator.push로 인한 leading 버튼 없애기
          title: AppBarTitle(title: '자유 게시판'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          actions: [
            Visibility(
              visible: (newPost.uid == userProvider.uid),
              // 작성자 id와 같아야 함
              child: GestureDetector(
                child: isEditing
                    ? Icon(Icons.save, color: Colors.white)
                    : Icon(Icons.edit, color: Colors.white),
                onTap: () {
                  if (isEditing) {
                    setNewPost();
                    CustomAlertDialog.onSavePressed(
                      context: context,
                      post: post,
                      newPost: newPost,
                      fileBytes: fileBytes,
                    );
                  }
                  setState(() => isEditing = !isEditing);
                },
              ),
            ), // 수정하기 버튼
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                isEditing
                    ? await CustomAlertDialog.onBackPressed(
                        context, relativePath)
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
                        hintText: newPost.uid,
                        iconData: Icons.person,
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      CustomTextField(
                        controller: _titleController,
                        iconData: Icons.title,
                        isReadOnly: !isEditing,
                      ), // 제목
                      CustomTextField(
                        controller: _contentController,
                        iconData: Icons.description,
                        isReadOnly: !isEditing,
                      ), // 본문
                      CustomTextField(
                        hintText: newPost.modifyDate ?? newPost.createdDate,
                        iconData: Icons.calendar_month,
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      SizedBox(height: ConstSet.mediumGap),
                      fileBytes != null ? pdfOrImgView() : Text('이미지가 없습니다'),
                      isEditing ? fileSelect() : Container(),
                      // if (recognizedText != null) translateText(),
                      CustomTextField(
                        controller: _translateController,
                        iconData: Icons.g_translate,
                        isReadOnly: !isEditing,
                      ),
                      CustomTextField(
                        controller: _keywordController,
                        iconData: Icons.key,
                        isReadOnly: !isEditing,
                      ),
                      isSearch ? searchResult() : Container(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        floatingActionButton: !isEditing && newPost.uid == userProvider.uid
            ? FloatingActionButton(
                onPressed: () =>
                    CustomAlertDialog.onDeletePressed(context, newPost),
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
              if (isEditing) pdfToImgButton() else Container()
            ],
          )
        : Image.memory(fileBytes!, fit: BoxFit.cover);
  }

  Widget pdfToImgButton() {
    return ElevatedButton(
      onPressed: () async {
        CustomLoadingDialog.showLoadingDialog(context, '이미지 변환중입니다');
        Map<String, dynamic>? result =
            await FileProcessing.pdfToPng(fileBytes: fileBytes);
        if (result == null) return;
        CustomLoadingDialog.pop(context);
        await _setResult(result);
      },
      child: Row(
        children: [Icon(Icons.transform), Text('pdf를 이미지로 변환하기')],
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
            var result = await FileProcessing.getImage(
                picker: _picker, imageSource: ImageSource.camera);
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
            CustomLoadingDialog.showLoadingDialog(context, '텍스트 변환중입니다');
            RecognizedText? result = await FileProcessing.inputFileToText(
              textRecognizer: _textRecognizer,
              internalPath: internalPath,
            );
            CustomLoadingDialog.pop(context);
            if (result != null) {
              _translateController.text = result.text;
              recognizedText = result;
              setState(() {});
            }
          },
          icon: Icon(Icons.g_translate),
          iconSize: 30.0,
        ),
        IconButton(
          onPressed: () async {
            if (validateCheck()) return;
            CustomLoadingDialog.showLoadingDialog(context, '텍스트 키워드 추출중입니다.');
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
            CustomLoadingDialog.showLoadingDialog(context, '강의를 검색중입니다.');
            String? result = await FileProcessing.makeSummary(
                text: _translateController.text,
                keywords: _keywordController.text);
            // Map<String, dynamic>? result =
            //     await FileProcessing.searchKmooc(
            //         keywordController.text);
            CustomLoadingDialog.pop(context);
            if (result != null) {
              print(result);
              setState(() => isSearch = true);
            }
          },
          icon: Icon(Icons.search),
          iconSize: 30.0,
        ),
      ],
    );
  }

  Widget searchResult() => Text('강의 검색 결과가 없습니다');

  bool validateCheck() {
    if (fileBytes != null && !isPdf && internalPath != null) return false;
    if (fileBytes == null) CustomToast.showToast('파일을 선택하세요');
    if (isPdf) CustomToast.showToast('이미지로 변환해주세요');
    if (internalPath == null) CustomToast.showToast('파일을 새롭게 업로드 한 뒤 시도해주세요');
    return true;
  }
}
// Widget translateText() {
//   return ListView.separated(
//     shrinkWrap: true,
//     // 리스트 뷰 크기 고정
//     primary: false,
//     // 리스트 뷰 내부 스크롤 없음
//     itemCount: recognizedText!.blocks.length,
//     itemBuilder: (context, index) {
//       TextBlock textBlock = recognizedText!.blocks[index];
//       return Card(
//         margin: EdgeInsets.all(8.0),
//         child: ListTile(
//           title: Text('Text Block #$index'),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: textBlock.lines.map((line) => Text(line.text)).toList(),
//           ),
//         ),
//       );
//     },
//     separatorBuilder: (BuildContext context, int index) => Divider(),
//   );
// }
