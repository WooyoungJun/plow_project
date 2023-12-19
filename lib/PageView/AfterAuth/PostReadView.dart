import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';
import '../../components/CustomClass/CustomDrawer.dart';
import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomToast.dart';
import '../../components/PostHandler.dart';
import '../../components/FileProcessing.dart';
import '../../components/const/Size.dart';

class PostReadView extends StatefulWidget {
  @override
  State<PostReadView> createState() => _PostReadViewState();
}

class _PostReadViewState extends State<PostReadView> {
  late UserProvider userProvider;
  late Post post;
  late int index;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController translateController = TextEditingController();
  bool isEditing = false;
  bool isUpload = false;
  bool isTranslate = false;

  final _picker = ImagePicker();
  String? relativePath;
  String? downloadURL;
  String? fileName;

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    post = argRef['post'] as Post;
    index = argRef['index'] as int;
    titleController.text = post.title;
    contentController.text = post.content;
    relativePath = post.relativePath;
    downloadURL = post.downloadURL;
    fileName = post.fileName;
    if (post.translateContent != null) {
      translateController.text = post.translateContent!;
    }
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
        (translateController.text != '')) {
      Post updatedPost = Post(
        postId: post.postId,
        uid: userProvider.uid!,
        title: titleController.text,
        content: contentController.text,
        translateContent: translateController.text,
      );
      if (relativePath != null) {
        Map<String, String>? result =
        await FileProcessing.transitionToStorage(relativePath!, fileName!);
        if (result != null) {
          updatedPost.relativePath = result['relativePath'];
          updatedPost.downloadURL = result['downloadURL'];
          updatedPost.fileName = result['fileName'];
        }
      }
      await PostHandler.updatePost('BoardList', updatedPost); // post 업데이트
      post = updatedPost;
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
          // content: Text('정말 삭제하시겠습니까?'),
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
                    await PostHandler.deletePost(
                        'BoardList', post.postId, post.relativePath);
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.pop(context, {'isDelete': true});
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void setResult(Map<String, String>? result) {
    if (result != null) {
      relativePath = result['relativePath'];
      downloadURL = result['downloadURL'];
      fileName = result['fileName'];
      translateController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
                setState(() {
                  if (isEditing) {
                    _handleSaveButton();
                  } else {
                    isEditing = !isEditing;
                  }
                });
              },
            ),
          ), // 수정하기 버튼
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () =>
                Navigator.pop(context, {'post': post}),
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
                isReadOnly: !isEditing,
              ), // 제목
              CustomTextField(
                controller: contentController,
                icon: Icon(Icons.description),
                isReadOnly: !isEditing,
              ), // 본문
              CustomTextField(
                hintText: post.createdDate,
                icon: Icon(Icons.calendar_month),
                isReadOnly: true,
              ),
              SizedBox(height: largeGap),
              Padding(
                padding: EdgeInsets.all(16.0),
                child:
                    FileProcessing.imageOrText(downloadURL: downloadURL),
              ), // 작성일
              if (isEditing)
                Column(
                  children: [
                    SizedBox(height: largeGap),
                    Column(
                      children: [
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
                        SizedBox(height: largeGap),
                        ElevatedButton(
                          onPressed: () async {
                            String? result =
                                await FileProcessing.fileToText(downloadURL);
                            if (result != null) {
                              translateController.text = result;
                              setState(() => isTranslate = true);
                            }
                          },
                          child: Text('텍스트 변환'),
                        )
                      ],
                    )
                  ],
                )
              else
                Container(),
              CustomTextField(
                controller: translateController,
                icon: Icon(Icons.g_translate),
                isReadOnly: !isTranslate && !isEditing,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !isEditing
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
