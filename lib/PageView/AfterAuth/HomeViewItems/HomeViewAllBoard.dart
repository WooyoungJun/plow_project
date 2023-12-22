import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';

class HomeViewAllBoard extends StatefulWidget {
  const HomeViewAllBoard({super.key});

  @override
  State<HomeViewAllBoard> createState() => _HomeViewAllBoardState();
}

class _HomeViewAllBoardState extends State<HomeViewAllBoard> {
  late UserProvider userProvider;
  List<Post> posts = [];
  bool _isInitComplete = false;
  double visibleCount = 15; // 화면에 표시할 게시글 갯수
  late double screenHeight;
  late double itemHeight;

  Future<void> getData({List<String>? uids}) async {
    posts = await PostHandler.readPost(
        collection: 'BoardList', uids: uids, limit: 10); // 모든 글 중 10개 읽어오기
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
    screenHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.bottom;
    itemHeight = screenHeight / visibleCount;
    await getData();
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: AppBarTitle(title: '자유 게시판'),
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
              CustomLoadingDialog.showLoadingDialog(
                  context, '새로고침 중입니다.');
              await getData();
              CustomLoadingDialog.pop(context);
              setState(() => CustomToast.showToast('새로고침 완료'));
            },
          )
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
    );
  }
}
