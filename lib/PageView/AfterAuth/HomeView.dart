import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomDrawer.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';
import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomProgressIndicator.dart';
import '../../components/PostHandler.dart';
import '../../components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();

}

class _HomeViewState extends State<HomeView>{
  late UserProvider userProvider;
  List<Post> posts = [];
  bool _isInitComplete = false;

  Future<void> getData(List<String> uids) async {
    posts = await PostHandler.readPost('BoardList', uids);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeView());
  }

  // 초기 설정
  // userProvider -> 사용자 정보
  // post 읽어오기
  // inInitComplete -> ProgressIndicator 띄울 수 있도록 초기화 상태 체크
  Future<void> initHomeView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    await getData([userProvider.uid!]);
    setState(() => _isInitComplete = true);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
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
                  Navigator.pop(context); // 작성 후 뒤돌아갔을 때 BottomSheet 없애기 위해 pop
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
    if (!_isInitComplete) return CustomProgressIndicator();
    double screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.bottom; // 화면의 높이 계산
    double visibleCount = 15; // 화면에 표시할 게시글 갯수
    double itemHeight = screenHeight / visibleCount; // 각 아이템 높이
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '자유 게시판'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context)
                .openDrawer(), // builder 사용해야 현재 Scaffold 위젯 참조 가능
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/PostUploadView').then((result) {
                result = result as Map<String, Post>?;
                if (result != null) {
                  Post newPost = result['post']!; // post add 완료 했으면 post 존재
                  setState(() => posts.add(newPost)); // post 추가 하고 setState
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () {
              getData([userProvider.uid!]);
              setState(() => CustomToast.showToast('새로고침 완료'));
            },
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
        itemCount: posts.length,
        itemExtent: itemHeight,
        itemBuilder: (context, index) {
          final post = posts[index];
          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/PostReadView',
                  arguments: {'post': post}).then((result) {
                result = result as Map<String, Post?>?;
                if (result != null) {
                  Post? post = result['post'];
                  setState(() {
                    if (post != null) {
                      posts[index] = post;
                    } else {
                      posts.removeAt(index);
                    }
                  });
                }
              });
            },
            child: Container(
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
                  Text(post.title, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        // backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        // 각 항목 일정 너비, 화면 아래 고정된 탭 표시
        showSelectedLabels: false,
        showUnselectedLabels: false,
        // 라벨 숨기기
        currentIndex: 0,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            activeIcon: Icon(Icons.home_sharp),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            activeIcon: Icon(Icons.group_sharp),
            label: 'friend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_add),
            activeIcon: Icon(Icons.group_add_sharp),
            label: 'friend manage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            activeIcon: Icon(Icons.person_sharp),
            label: 'My Info',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showBottomSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}
