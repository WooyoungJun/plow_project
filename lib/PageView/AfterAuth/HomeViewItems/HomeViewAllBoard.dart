import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/PostHandler.dart';

class HomeViewAllBoard extends StatefulWidget {
  final double itemHeight;
  final int visibleCount;

  HomeViewAllBoard({required this.itemHeight, required this.visibleCount});

  @override
  State<HomeViewAllBoard> createState() => _HomeViewAllBoardState();
}

class _HomeViewAllBoardState extends State<HomeViewAllBoard> {
  late int _totalPages;
  late int _totalPosts;
  int _curPage = 1;
  int _startPage = 1;
  List<Post> posts = [];
  bool _isInitComplete = false;

  Future<void> getData({required int page}) async {
    posts = await PostHandler.readPostAll(
      totalPosts: _totalPosts,
      limit: widget.visibleCount - 2,
      page: _curPage,
    ); // 모든 글 중 10개 읽어오기
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
    _totalPosts = await PostHandler.totalPostCount;
    _totalPages = (_totalPosts / (widget.visibleCount - 2)).ceil();
    await getData(page: _curPage);
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '자유 게시판'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/PostUploadView',
                      arguments: {'curPage': _curPage, 'endPage': _totalPages})
                  .then((result) async {
                result = result as Map<String, Post>?;
                if (result != null) {
                  await getData(page: _curPage);
                  setState(() {}); // post 추가 하고 setState
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: () async {
              CustomLoadingDialog.showLoadingDialog(context, '새로고침 중입니다.');
              await getData(page: _curPage);
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
                    Navigator.pushNamed(context, '/PostReadView', arguments: {
                      'curPage': _curPage,
                      'endPage': _totalPages,
                      'post': post
                    }).then((result) async {
                      result = result as Map<String, bool?>?;
                      if (result != null) {
                        await getData(page: _curPage);
                        setState(() {});
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
                min(_totalPages, 10), // 최대 10페이지까지 표시
                (index) {
                  return GestureDetector(
                    onTap: () async {
                      CustomLoadingDialog.showLoadingDialog(
                          context, '로딩 중입니다.');
                      _curPage = index + 1;
                      _startPage = _curPage - 5;
                      if (_startPage < 1) _startPage = 1;
                      await getData(page: _curPage);
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