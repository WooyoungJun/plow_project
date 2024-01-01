import 'package:flutter/material.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewFriendMangae.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewAllBoard.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewFriendBoard.dart';
import 'package:plow_project/PageView/AfterAuth/HomeViewItems/HomeViewMyInfo.dart';

class HomeView extends StatefulWidget {
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late List<Widget> homeViewItems;
  bool _isInitComplete = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeView());
  }

  // AppBar, BottomNavigationBar 제외한 screenHeight 기반 height 상수 설정
  Future<void> initHomeView() async {
    double screenHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        kBottomNavigationBarHeight;
    ConstSet.setHeights(screenHeight);
    homeViewItems = [
      HomeViewAllBoard(),
      HomeViewFriendBoard(),
      HomeViewFriendManage(),
      HomeViewMyInfo()
    ];
    setState(() => _isInitComplete = true);
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
