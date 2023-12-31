import 'dart:typed_data';
import 'package:flutter/material.dart';
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
import 'package:plow_project/components/const/Size.dart';

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late int vc;
  late double contentHeight;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _translateController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.korean);
  bool _isInitComplete = false;
  bool isPdf = false;
  bool isEditing = false;

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
    vc = argRef['vc'] as int;
    _titleController.text = post.title;
    _contentController.text = post.content;
    _translateController.text = post.translateContent ?? '';
    fileBytes = await FileProcessing.loadFileFromStorage(
        relativePath: post.relativePath);
    contentHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        kBottomNavigationBarHeight;
    isPdf = post.checkPdf(isPdf: isPdf, anotherFileName: fileName);
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
      isPdf = post.checkPdf(isPdf: isPdf, anotherFileName: fileName);
      _translateController.clear();
      setState(() {});
    }
  }

  Future<void> _handleSaveButton() async {
    if (_titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }
    if ((post.title != _titleController.text) ||
        (post.content != _contentController.text) ||
        (relativePath != null) ||
        (_translateController.text != post.translateContent) ||
        (_keywordController.text != post.keywordContent)) {
      CustomLoadingDialog.showLoadingDialog(context, '업로드 중입니다. \n잠시만 기다리세요');
      post.title = _titleController.text;
      post.content = _contentController.text;
      post.translateContent = _translateController.text;
      post.keywordContent = _keywordController.text;
      Map<String, dynamic>? result = await FileProcessing.transitionToStorage(
          relativePath: relativePath, fileName: fileName, fileBytes: fileBytes);
      if (result != null) {
        FileProcessing.deleteFile(relativePath: post.relativePath);
        post.relativePath = result['relativePath'];
        post.fileName = result['fileName'];
      }
      await PostHandler.updatePost(post); // post 업데이트
      CustomLoadingDialog.pop(context);
      Navigator.pop(context, {'update': true});
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
                    await FileProcessing.deleteFile(
                        relativePath: post.relativePath);
                    await PostHandler.deletePost(post, vc);
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

  Future<void> _onBackPressed(BuildContext context) async {
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
                await FileProcessing.deleteFile(relativePath: relativePath);
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
        await _onBackPressed(context);
      },
      child: Scaffold(
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
                    ? Icon(Icons.save, color: Colors.white)
                    : Icon(Icons.edit, color: Colors.white),
                onTap: () {
                  isEditing
                      ? _handleSaveButton()
                      : setState(() => isEditing = !isEditing);
                },
              ),
            ), // 수정하기 버튼
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                isEditing
                    ? await _onBackPressed(context)
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
                constraints: BoxConstraints(minHeight: contentHeight),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: post.uid,
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
                        hintText: post.modifyDate ?? post.createdDate,
                        iconData: Icons.calendar_month,
                        isReadOnly: true,
                        maxLines: 1,
                      ),
                      SizedBox(height: mediumGap),
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
            validateCheck();
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
            validateCheck();
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
            validateCheck();
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
              setState(() {});
            }
          },
          icon: Icon(Icons.search),
          iconSize: 30.0,
        ),
      ],
    );
  }

  Widget searchResult() => Text('강의 검색 결과가 없습니다');

  void validateCheck() {
    if (fileBytes == null) return CustomToast.showToast('파일을 선택하세요');
    if (isPdf) return CustomToast.showToast('이미지로 변환해주세요');
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
