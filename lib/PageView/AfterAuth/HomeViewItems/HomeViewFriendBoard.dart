import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/ConstSet.dart';

class HomeViewFriendBoard extends StatefulWidget {
  @override
  State<HomeViewFriendBoard> createState() => _HomeViewAllBoardState();
}

class _HomeViewAllBoardState extends State<HomeViewFriendBoard> {
  late UserProvider userProvider;
  int? _last;
  int refreshGetPost = 5;
  List<Post> posts = [];
  bool _isInitComplete = false;

  // 추가 데이터 가져올때 하단 인디케이터 표시용
  bool isMoreRequesting = false;

  // 다음 데이터 위치를 파악하기 위함
  int nextPage = 0;

  // 서버에 저장되어 있는 데이터들(가상으로 사용하기 위해)
  List<String> serverItems = [];

  // 실제 데이터를 서버에 가져와 저장되는 데이터(리스트에 표시할때 사용)
  List<String> items = [];

  // 드레그 거리를 체크하기 위함
  // 해당 값을 평균내서 50%이상 움직였을때 데이터 불러오는 작업을 하게됨.
  double _dragDistance = 0;

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

  Future<void> getData({int? last}) async {
    Map<String, dynamic> results = await PostHandler.readPostFriend(
      friend: userProvider.friend,
      last: last,
    );
    var tmp = results['posts'].cast<Post>();
    if (tmp.length != 0) {
      if (last == null) {
        posts = tmp;
      } else {
        posts.addAll(tmp);
      }
      _last = posts.last.postId;
    }
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
              Navigator.pushNamed(context, '/PostUploadView')
                  .then((result) async {
                result = result as Map<String, dynamic>?;
                if (result != null) {
                  await getData();
                  setState(() {}); // post 추가 하고 setState
                }
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
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                scrollNotification(notification);
                return false;
              },
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
                            arguments: {
                              'post': post,
                            }).then((result) async {
                          result = result as Map<String, dynamic>?;
                          if (result != null) {
                            await getData();
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
          ),
          Container(
            height: isMoreRequesting ? 50.0 : 0,
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  //스크롤 이벤트 처리
  scrollNotification(notification) async {
    // 스크롤 최대 범위
    var containerExtent = notification.metrics.viewportDimension;
    var bottom = notification.metrics.maxScrollExtent;

    if (notification is ScrollStartNotification) {
      // 스크롤을 시작하면 발생(손가락으로 리스트를 누르고 움직이려고 할때)
      // 스크롤 거리값을 0으로 초기화함
      _dragDistance = 0;
    } else if (notification is OverscrollNotification) {
      // 안드로이드에서 동작
      // 스크롤을 시작후 움직일때 발생(손가락으로 리스트를 누르고 움직이고 있을때 계속 발생)
      // 스크롤 움직인 만큼 빼준다.(notification.overscroll)
      _dragDistance -= notification.overscroll;
    } else if (notification is ScrollUpdateNotification) {
      // ios에서 동작
      // 스크롤을 시작후 움직일때 발생(손가락으로 리스트를 누르고 움직이고 있을때 계속 발생)
      // 스크롤 움직인 만큼 빼준다.(notification.scrollDelta)
      _dragDistance -= notification.scrollDelta!;
    } else if (notification is ScrollEndNotification) {
      // 스크롤이 끝났을때 발생(손가락을 리스트에서 움직이다가 뗐을때 발생)

      // 지금까지 움직인 거리를 최대 거리로 나눈다.
      var percent = _dragDistance / (containerExtent);
      // 해당 값이 -0.4(40프로 이상) 아래서 위로 움직였다면
      if (percent <= -0.4) {
        // bottom 리스트 가장 아래 위치 값
        // pixels는 현재 위치 값
        // 두 같이 같다면(스크롤이 가장 아래에 있다)
        if (bottom == notification.metrics.pixels) {
          setState(() {
            // 서버에서 데이터를 더 가져오는 효과를 주기 위함
            // 하단에 프로그레스 서클 표시용
            isMoreRequesting = true;
          });

          // 서버에서 데이터 가져온다.
          await getData(last: _last).then((value) {
            setState(() {
              // 다 가져오면 하단 표시 서클 제거
              isMoreRequesting = false;
            });
          });
        }
      }
    }
  }

  Future<void> refresh() async {
    CustomLoadingDialog.showLoadingDialog(context, '새로고침 중입니다.');
    await getData();
    CustomLoadingDialog.pop(context);
    setState(() => CustomToast.showToast('새로고침 완료'));
  }
}
