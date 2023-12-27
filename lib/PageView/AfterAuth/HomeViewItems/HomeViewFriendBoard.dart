import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';

class HomeViewFriendBoard extends StatefulWidget {
  final double itemHeight;
  final int visibleCount;

  HomeViewFriendBoard({required this.itemHeight, required this.visibleCount});

  @override
  State<HomeViewFriendBoard> createState() => _HomeViewAllBoardState();
}

class _HomeViewAllBoardState extends State<HomeViewFriendBoard> {
  late UserProvider userProvider;
  late int _totalFriendPages;
  late int _totalFriendPosts;
  int _curPage = 1;
  int _startPage = 1;
  late int _start;
  late int _end;
  List<Post> posts = [];
  bool _isInitComplete = false;

  Future<void> getData(
      {List<String>? uids, required int start, required int end}) async {
    print('$start, $end');
    posts = await PostHandler.readPostAll(
      totalPosts: _totalFriendPosts,
      limit: widget.visibleCount - 2,
      page: _curPage,
    );
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
    _totalFriendPosts =
        await PostHandler.totalFriendPostCount(userProvider.friend);
    _totalFriendPages = (_totalFriendPosts / widget.visibleCount).ceil();
    _start = (_curPage - 1) * (widget.visibleCount - 2);
    _end = (_curPage) * (widget.visibleCount - 2);
    await getData(uids: userProvider.friend, start: _start, end: _end);
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
      appBar: AppBar(
        leading: Container(),
        // Navigator.push로 인한 leading 버튼 없애기
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '친구 게시판'),
        centerTitle: true,
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
            onPressed: () async {
              CustomLoadingDialog.showLoadingDialog(context, '새로고침 중입니다.');
              await getData(
                  uids: userProvider.friend, start: _start, end: _end);
              CustomLoadingDialog.pop(context);
              setState(() => CustomToast.showToast('새로고침 완료'));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              itemCount: posts.length,
              itemExtent: widget.itemHeight,
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
          ),
          // 페이지네이션 링크 표시
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                min(_totalFriendPages, 10), // 최대 10페이지까지 표시
                (index) {
                  int vc = widget.visibleCount;
                  int start = (_startPage - 1 + index) * (vc - 2);
                  int end = (_startPage + index) * (vc - 2);

                  return GestureDetector(
                    onTap: () async {
                      CustomLoadingDialog.showLoadingDialog(
                          context, '로딩 중입니다.');
                      _curPage = index + 1;
                      _startPage = _curPage - 5;
                      if (_startPage < 1) _startPage = 1;
                      _start = start;
                      _end = end;
                      await getData(start: _start, end: _end);
                      CustomLoadingDialog.pop(context);
                      setState(() {});
                    },
                    child: Container(
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${_startPage + index}',
                        style: TextStyle(
                          fontSize: 16,
                          color: (_startPage + index) == _curPage
                              ? Colors.blue
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
