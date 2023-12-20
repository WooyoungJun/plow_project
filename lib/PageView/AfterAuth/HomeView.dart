import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomDrawer.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';
import '../../components/AppBarTitle.dart';
import '../../components/PostHandler.dart';
import '../../components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late UserProvider userProvider;
  List<Post> posts = [];

  Future<void> getData() async {
    posts = await PostHandler.readPost('BoardList', userProvider.uid!);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    userProvider = Provider.of<UserProvider>(context);
    await getData();
    setState((){});
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
    double screenHeight = MediaQuery.of(context).size.height; // 화면의 높이 계산
    double visibleCount = 15;
    double itemHeight = screenHeight / visibleCount;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: AppBarTitle(title: '자유 게시판'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              getData();
              setState(() => CustomToast.showToast('새로고침 완료'));
            },
            icon: Icon(Icons.sync),
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
      body: ListView.builder(
        // shrinkWrap: true, // 길이 맞게 위젯 축소 허용
        itemCount: posts.length,
        itemExtent: itemHeight, // 각 문서의 높이
        itemBuilder: (context, index) {
          final post = posts[index];
          return InkWell(
            onTap: () => Navigator.pushNamed(context, '/PostReadView',
                arguments: {'post': post, 'index': index}).then((result) {
              result = result as Map<String, dynamic>?;
              if (result != null) {
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
              height: itemHeight,
              margin: EdgeInsets.only(left: 6, right: 6, top: 6),
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
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: mediumGap),
                  Text(
                    post.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
