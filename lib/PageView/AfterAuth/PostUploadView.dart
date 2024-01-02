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
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool isInitComplete = false;
  bool isPdf = false;
  bool isTranslate = false;
  bool isKeyExtraction = false;
  bool isSearch = false;

  final _picker = ImagePicker();
  String? internalPath;
  Uint8List? fileBytes;
  RecognizedText? recognizedText;

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
      setState(() {});
    }
  }

  void setNewPost() {
    newPost.title = _titleController.text;
    newPost.content = _contentController.text;
    newPost.translateContent = _translateController.text;
    newPost.keywordContent = _keywordController.text;
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
                          hintText: userProvider.userName,
                          iconData: Icons.person,
                          isReadOnly: true,
                          maxLines: 1,
                        ),
                        CustomTextField(
                          controller: _titleController,
                          iconData: Icons.title,
                          isReadOnly: false,
                        ),
                        CustomTextField(
                          controller: _contentController,
                          iconData: Icons.description,
                          isReadOnly: false,
                        ),
                        SizedBox(height: ConstSet.largeGap),
                        fileBytes != null ? pdfOrImgView() : Text('이미지가 없습니다'),
                        SizedBox(height: ConstSet.largeGap),
                        fileSelect(),
                        SizedBox(height: ConstSet.largeGap),
                        // isTranslate ? translateText() : Container(),
                        CustomTextField(
                          controller: _translateController,
                          iconData: Icons.g_translate,
                          isReadOnly: !isTranslate,
                        ),
                        CustomTextField(
                          controller: _keywordController,
                          iconData: Icons.key,
                          isReadOnly: !isKeyExtraction,
                        ),
                        isSearch ? searchResult() : Container(),
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
        : Image.memory(fileBytes!, fit: BoxFit.cover);
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
        children: [Icon(Icons.transform), Text('pdf를 이미지로 변환하기')],
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
            CustomLoadingDialog.showLoadingDialog(context, '텍스트 변환중입니다');
            RecognizedText? result = await FileProcessing.inputFileToText(
              textRecognizer: _textRecognizer,
              internalPath: internalPath,
            );
            CustomLoadingDialog.pop(context);
            if (result != null) {
              _translateController.text = result.text;
              recognizedText = result;
              setState(() => isTranslate = true);
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
              setState(() => isKeyExtraction = true);
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
            //     await FileProcessing.searchKmooc(keywordController.text);
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
    if (fileBytes != null && !isPdf) return false;
    if (fileBytes == null) CustomToast.showToast('파일을 선택하세요');
    if (isPdf) CustomToast.showToast('이미지로 변환해주세요');
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
