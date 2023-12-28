import 'package:flutter/material.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewFriendMangae.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewAllBoard.dart';
// import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewFriendBoard.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewMyInfo.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late UserProvider userProvider;
  late List<Widget> homeViewItems;
  bool _isInitComplete = false;
  List<Post> posts = [];
  int _currentIndex = 0;

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
    double screenHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        kBottomNavigationBarHeight;
    int visibleCount = 12;
    double itemHeight = screenHeight / visibleCount;
    homeViewItems = [
      HomeViewAllBoard(itemHeight: itemHeight, visibleCount: visibleCount),
      // HomeViewFriendBoard(itemHeight: itemHeight, visibleCount: visibleCount),
      Text('2'),
      HomeViewFriendManage(),
      HomeViewMyInfo()
    ];
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      body: Center(child: homeViewItems[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // 각 항목 일정 너비, 화면 아래 고정된 탭 표시
        showSelectedLabels: false,
        showUnselectedLabels: false,
        // 라벨 숨기기
        currentIndex: _currentIndex,
        elevation: 0,
        onTap: (int index) => setState(() => _currentIndex = index),
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
    );
  }
}
