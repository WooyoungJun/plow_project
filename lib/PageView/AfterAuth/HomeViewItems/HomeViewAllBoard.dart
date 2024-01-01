import 'dart:math';
import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomTextStyle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';

class HomeViewAllBoard extends StatefulWidget {
  @override
  State<HomeViewAllBoard> createState() => _HomeViewAllBoardState();
}

class _HomeViewAllBoardState extends State<HomeViewAllBoard> {
  late int _totalPages;
  int _curPage = 1;
  int _startPage = 1;
  List<Post> posts = [];
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await initHomeView());
  }

  Future<void> initHomeView() async {
    await getData(page: _curPage);
    setState(() => _isInitComplete = true);
  }

  Future<void> getData({required int page}) async {
    Map<String, dynamic> results =
        await PostHandler.readPostAll(page: _curPage);
    posts = results['posts'].cast<Post>();
    int totalPosts = results['totalPosts'] as int;
    _totalPages = (totalPosts / (ConstSet.limit)).ceil();
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
              Navigator.pushNamed(context, '/PostUploadView')
                  .then((result) async {
                result = result as Map<String, dynamic>?;
                if (result != null) await refresh();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.sync, color: Colors.white),
            onPressed: refresh,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: posts.length,
                itemExtent: ConstSet.itemHeight,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/PostReadView',
                          arguments: {'post': post}).then((result) async {
                        result = result as Map<String, dynamic>?;
                        if (result != null) await refresh();
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
                            color: Colors.grey.withOpacity(0.3),
                            offset: Offset(0, 2),
                          ),
                        ],
                        // 입체감을 위해 설정
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 4, 0, 4),
                            child: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                '${index + 1}',
                                style: CustomTextStyle.style(16),
                              ),
                            ),
                          ),
                          SizedBox(width: ConstSet.mediumGap),
                          Text(post.title, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 페이지네이션 링크 표시
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                min(_totalPages, 10), // 최대 10페이지까지 표시
                (index) {
                  int page = _startPage + index;
                  return GestureDetector(
                    onTap: () async {
                      CustomLoadingDialog.showLoadingDialog(
                          context, '로딩 중입니다.');
                      _curPage = index + 1;
                      _startPage = _curPage - 5;
                      if (_curPage > _totalPages - 4) {
                        // 최종 페이지 기준 중간 이상이면 startPage 조정
                        _startPage = _totalPages - 9;
                      }
                      if (_startPage < 1) _startPage = 1;

                      await getData(page: _curPage);
                      CustomLoadingDialog.pop(context);
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color: page == _curPage ? Colors.blue : null,
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

  Future<void> refresh() async {
    CustomLoadingDialog.showLoadingDialog(context, '새로고침 중입니다.');
    await getData(page: _curPage);
    CustomLoadingDialog.pop(context);
    setState(() => CustomToast.showToast('새로고침 완료'));
  }
}
