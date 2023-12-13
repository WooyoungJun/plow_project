import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomDrawer.dart';
import 'package:plow_project/components/CustomTextField.dart';
import 'package:provider/provider.dart';
import '../components/AppBarTitle.dart';
import '../components/DataHandler.dart';
import '../components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String? uid;
  List<Todo> todos = [];

  @override
  void initState() {
    super.initState();
    // build 이후에 실행시킬 부분
    // (build에서 async 직접 사용하긴 힘듦)
    WidgetsBinding.instance.addPostFrameCallback((_) => getData());
  }

  // 사용자 uid로 POST 가져오기
  Future<void> getData() async {
    todos = await DataInFireStore.readPost('BoardList', uid!);
    setState(() {});
  }

  bool checkUpdate(String a, String b) {
    if (a == b) {
      return true;
    } else {
      return false;
    }
  }

  // 추가 or 수정하기 tab
  Future<void> onAddOrUpdateTab(
      {Todo? todo, int? index, required bool isAdd}) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();

    // 수정 하기
    if (!isAdd) {
      titleController.text = todo!.title;
      contentController.text = todo.content;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAdd ? '추가하기' : '수정하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: titleController,
                labelText: 'Title',
                icon: Icon(Icons.title),
              ).widget,
              CustomTextField(
                controller: contentController,
                labelText: 'content',
                icon: Icon(Icons.description),
              ).widget,
            ],
          ), // title, content 수정
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소하기'),
            ), // 취소하기 버튼
            TextButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  return showToast('제목은 비어질 수 없습니다');
                }
                if (isAdd) {
                  // 둘 중 하나라도 다르면 true
                  Todo newTodo = Todo(
                      postId: '',
                      uid: uid!,
                      title: titleController.text,
                      content: contentController.text,
                      createdDate: Timestamp.now());
                  newTodo =
                      await DataInFireStore.addPost('BoardList', newTodo, uid!);
                  setState(() => todos.add(newTodo));
                  Navigator.of(context).pop();
                } else {
                  if (!(checkUpdate(todo!.title, titleController.text) &&
                      checkUpdate(todo.content, contentController.text))) {
                    Todo updatedTodo = Todo(
                      postId: todo.postId,
                      uid: uid!,
                      title: titleController.text,
                      content: contentController.text,
                      createdDate: todo.createdDate,
                    );
                    await DataInFireStore.updatePost('BoardList', updatedTodo);
                    setState(() => todos[index!] = updatedTodo);
                    Navigator.of(context).pop();
                  } else {
                    return showToast('변경 사항이 없습니다!');
                  }
                }
              },
              child: Text(isAdd ? '추가하기' : "수정하기"),
            ),
          ],
        );
      },
    );
  }

  // 하단 메뉴를 표시하는 함수
  Future<void> _showBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 작성 후 뒤돌아왔을 때 BottomSheet 없애기 위해 pop
                  Navigator.pushNamed(context, '/PostView'); // 게시글 작성으로 넘어가기
                },
                child: Text('사진 업로드하기'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAddOrUpdateTab(isAdd: true);
                },
                child: Text('게시글 작성하기'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUser(); // user email, name 가져오기
    uid = userProvider.user?.uid;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '자유 게시판').widget,
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      // app바 title, leading, action 위젯, 오른쪽에서 열림
      body: ListView.builder(
        shrinkWrap: true, // 길이 맞게 위젯 축소 허용
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return Container(
            margin: EdgeInsets.only(left: 8, right: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(todo.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async => onAddOrUpdateTab(
                        isAdd: false,
                        todo: todo,
                        index: index,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit, color: Colors.blue),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await DataInFireStore.deletePost(
                            'BoardList', todo.postId);
                        setState(() => todos.removeAt(index));
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
        child: Icon(Icons.add),
        // onPressed: () => Navigator.pushNamed(context, '/PostView'),
        // onPressed: () => onAddOrUpdateTab(isAdd: true),
      ),
    );
  }
}
