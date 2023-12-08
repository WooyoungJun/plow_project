// 로그인 시 나오는 화면
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:plow_project/components/custom_drawer.dart';
import 'package:plow_project/components/custom_text_form_field.dart';
import 'package:provider/provider.dart';

import 'components/custom_appbar.dart';
import 'components/data_handler.dart';
import 'components/user_provider.dart';

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

  Future<void> getData() async {
    todos = await DataInFireStore.readPost(uid!);
    setState(() {});
  }

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
              CustomTextFormField(
                controller: titleController,
                labelText: 'Title',
                icon: Icon(Icons.title),
              ),
              CustomTextFormField(
                controller: contentController,
                labelText: 'content',
                icon: Icon(Icons.description),
              ),
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
                  return showToast('title cannot be empty');
                }
                if (isAdd) {
                  Todo newTodo = Todo(
                      postId: '',
                      memberId: uid!,
                      title: titleController.text,
                      content: contentController.text,
                      createdDate: Timestamp.now());
                  newTodo =
                      await DataInFireStore.addPost('BoardList', newTodo, uid!);
                  setState(() => todos.add(newTodo));
                } else {
                  Todo updatedTodo = Todo(
                    postId: todo!.postId,
                    memberId: uid!,
                    title: titleController.text,
                    content: contentController.text,
                    createdDate: todo.createdDate,
                  );
                  await DataInFireStore.updatePost('BoardList', updatedTodo);
                  setState(() => todos[index!] = updatedTodo);
                }
                Navigator.of(context).pop();
              },
              child: Text(isAdd ? '추가하기' : "수정하기"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    uid = userProvider.user?.uid;
    print('build 호출, $uid');
    return Scaffold(
      appBar: CustomAppBar(
        title: '자유 게시판',
        userProvider: userProvider,
      ),
      // app바 title, leading, action 위젯
      endDrawer: CustomDrawer(userProvider: userProvider),
      // 오른쪽에서 열림
      // resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => onAddOrUpdateTab(isAdd: true),
      ),
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
    );
  }
}
