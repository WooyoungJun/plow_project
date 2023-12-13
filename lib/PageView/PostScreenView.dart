import 'package:flutter/material.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:provider/provider.dart';

import '../components/AppBarTitle.dart';
import '../components/DataHandler.dart';

class PostScreenView extends StatefulWidget {
  @override
  State<PostScreenView> createState() => _PostScreenViewState();
}

class _PostScreenViewState extends State<PostScreenView> {
  late UserProvider _userProvider;
  bool isEditing = false;
  Todo? todo;

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserProvider>(context);
    todo = ModalRoute.of(context)?.settings.arguments as Todo?;
    if (todo == null) isEditing = true;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '게시글 읽기'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: !isEditing
              ? [
                  Card(child: ListTile(title: Text('제목: ${todo!.title}'))),
                  Card(child: ListTile(title: Text('내용: ${todo!.content}'))),
                  Card(
                      child: ListTile(title: Text('작성일: ${todo!.createdDate}'))),
                ]
              : <Widget>[UpdateTabView()],
        ),
      ),
    );
  }
}

class UpdateTabView extends StatelessWidget {
  final Todo? todo;
  UpdateTabView({this.todo});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (todo != null) {
      titleController.text = todo!.title;
      contentController.text = todo!.content;
    }
    return Container();
  }
}

