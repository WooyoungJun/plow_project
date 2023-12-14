import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomDrawer.dart';
import 'package:provider/provider.dart';
import '../../components/AppBarTitle.dart';
import '../../components/DataHandler.dart';
import '../../components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late UserProvider userProvider;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => getData());
  }

  Future<void> getData() async {
    posts = await DataInFireStore.readPost('BoardList', userProvider.uid!);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    posts = await DataInFireStore.readPost('BoardList', userProvider.uid!);
    setState(() {});
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
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
                  Navigator.pushNamed(context, '/PhotoUploadView').then((_) {});
                },
                child: Text('사진 업로드하기'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 작성 후 뒤돌아왔을 때 BottomSheet 없애기 위해 pop
                  Navigator.pushNamed(context, '/PostUploadView')
                      .then((result) {
                    result = result as Map<String, Post>?;
                    if (result != null) {
                      Post newPost = result['post']!; // post add 완료 했으면 post 존재
                      setState(() {
                        posts.add(newPost); // post 추가 하고 setState
                      });
                    }
                  });
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
    print('build');
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
      body: ListView.builder(
        shrinkWrap: true, // 길이 맞게 위젯 축소 허용
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, '/PostReadView',
                arguments: {'post': post, 'index': index}).then((result) {
              result = result as Map<String, dynamic>?;
              if (result != null && result['isUpdate'] as bool == true) {
                Post? post = result['post'] as Post?;
                setState(() {
                  if (post != null) {
                    posts[index] = post;
                  } else {
                    posts.removeAt(index);
                  }
                });
              }
            }),
            child: Container(
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
                  title: Text(post.title),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
