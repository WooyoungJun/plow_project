import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CustomClass/CustomToast.dart';

class PostHandler {
  static final FirebaseFirestore _store = FirebaseFirestore.instance;
  static final CollectionReference _boardList = _store.collection('BoardList');
  static final CollectionReference _totalPostCount =
      _store.collection('TotalPostCount');

  static Future<int> get totalPostCount async =>
      (await _totalPostCount.doc('count').get())['count'];

  static Future<int> totalFriendPostCount(List<String> friend) async {
    int totalCount = 0;
    for (String friendEmail in friend) {
      DocumentSnapshot friendSnapshot =
          await _totalPostCount.doc(friendEmail).get();
      if (friendSnapshot.exists) totalCount += friendSnapshot['count'] as int;
    }
    return totalCount;
  }

  static Future<void> setUserPostCount(String userEmail) async =>
      await _totalPostCount.doc(userEmail).set({'count': 0});

  // uid에 해당하는 유저의 게시글 가져오기
  static Future<Map<String, dynamic>> readPostAll(
      {required int page, required int limit}) async {
    try {
      List<Post> posts = [];
      int totalPosts = 0;
      await _store.runTransaction((transaction) async {
        var doc = (await transaction.get(_totalPostCount.doc('count')));
        List<int> postPageIndex = doc['postPageIndex'].cast<int>();
        totalPosts = doc['count'];
        if (postPageIndex.length == 1) return {'posts': [], 'totalPosts': 0};
        page = page < postPageIndex.length ? page : 1;
        int postId = postPageIndex[postPageIndex.length <= page ? 0 : page];
        var postList = await _boardList
            .orderBy('postId', descending: true)
            .startAt([postId])
            .limit(limit)
            .get();
        posts = postList.docs.map((doc) {
          return Post(
            postId: doc['postId'],
            uid: doc['uid'],
            title: doc['title'],
            content: doc['content'],
            createdDate: doc['createdDate'],
            modifyDate: doc['modifyDate'],
            translateContent: doc['translateContent'],
            relativePath: doc['relativePath'],
            fileName: doc['fileName'],
            prev: doc['prev'],
            next: doc['next'],
          );
        }).toList();
      });

      return {'posts': posts, 'totalPosts': totalPosts};
    } catch (err) {
      print(err);
      return {'posts': [], 'totalPosts': 0};
    }
  }

  // post 추가하기
  static Future<void> addPost(int startPage, Post post, int vc) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.createdDate = formattedTime;
    post.timeStamp = Timestamp.now();

    DocumentReference countDoc = _totalPostCount.doc('count');
    DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
    // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
    await _store.runTransaction((transaction) async {
      var topPost =
          await _boardList.orderBy('postId', descending: true).limit(1).get();
      var lastPost = await _boardList.orderBy('postId').limit(1).get();
      late int newPostId;
      if (topPost.docs.isEmpty) {
        newPostId = 1;
        // countDoc, userCountDoc 값 증가
        transaction.update(countDoc, {
          'count': FieldValue.increment(1),
          'postPageIndex': FieldValue.arrayUnion([newPostId])
        });
      } else {
        int topPostId = topPost.docs.first['postId'];
        int lastPostId = lastPost.docs.first['postId'];
        newPostId = topPostId + 1;
        // postPageIndex 변경
        var doc = (await transaction.get(countDoc));
        int count = doc['count'];
        List<int> postPageIndex = doc['postPageIndex'].cast<int>();
        int endPage = (count / vc).ceil();
        print('$startPage, $endPage');
        for (int page = startPage; page <= endPage; page++) {
          if (page == 1) {
            // 새로운 postId로 설정
            postPageIndex[1] = newPostId;
          } else {
            String postId = postPageIndex[page].toString();
            postPageIndex[page] =
                (await transaction.get(_boardList.doc(postId)))['next'];
            // 첫번째 페이지 첫번째 글 제외 모든 글은 next 존재하므로 null X
          }
        }
        if (count % vc == 0) postPageIndex.add(lastPostId);
        print('$lastPostId, $count, $vc, ${postPageIndex.last}');
        transaction.update(countDoc,
            {'count': FieldValue.increment(1), 'postPageIndex': postPageIndex});

        // next, prev 연결
        post.prev = topPostId;
        transaction
            .update(_boardList.doc(topPostId.toString()), {'next': newPostId});
      }

      // 공통 부분 -> postId 등록, userCount 증가
      post.postId = newPostId;
      transaction.set(_boardList.doc(newPostId.toString()), post.toMap());
      transaction.update(userCountDoc, {'count': FieldValue.increment(1)});
    });
    CustomToast.showToast('Post add 완료');
  }

  // post update
  static Future<void> updatePost(Post post) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.modifyDate = formattedTime;

    await _boardList.doc(post.postId.toString()).update(post.toMap());
    CustomToast.showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(int startPage, Post post, int vc) async {
    DocumentReference countDoc = _totalPostCount.doc('count');
    DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
    // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
    await _store.runTransaction((transaction) async {
      // postPageIndex 변경 -> 당겨오기
      var doc = (await transaction.get(countDoc));
      int count = doc['count'];
      List<int> postPageIndex = doc['postPageIndex'].cast<int>();
      int endPage = (count / vc).ceil();
      for (int page = startPage; page <= endPage; page++) {
        // 현재 페이지에서는 첫번째 글인 경우에만 변경 필요
        if (postPageIndex[page] != post.postId && page == startPage) continue;
        String postId = postPageIndex[page].toString();
        int? prevPostId = (await transaction
            .get(_boardList.doc(postId)))['prev']; // 마지막 글 제외 prev 항상 존재
        print(prevPostId);
        if (prevPostId != null) {
          postPageIndex[page] = prevPostId;
        } else {
          postPageIndex.removeLast();
        }
      }
      transaction.update(countDoc,
          {'postPageIndex': postPageIndex, 'count': FieldValue.increment(-1)});

      // prev, next 연결
      int? next = post.next;
      int? prev = post.prev;
      print(post.toMap());
      if (next != null && prev != null) {
        // 앞 뒤 존재
        transaction.update(_boardList.doc(next.toString()), {'prev': prev});
        transaction.update(_boardList.doc(prev.toString()), {'next': next});
      } else if (prev != null) {
        // 가장 최근 글
        transaction.update(_boardList.doc(prev.toString()), {'next': null});
      } else if (next != null) {
        // 맨 처음 글
        transaction.update(_boardList.doc(next.toString()), {'prev': null});
      }

      transaction.update(userCountDoc, {'count': FieldValue.increment(-1)});
      transaction.delete(_boardList.doc(post.postId.toString()));
    });
    CustomToast.showToast('Post delete 완료');
  }
}

class Post {
  Post({
    required this.uid,
    this.postId = -1,
    this.title = '',
    this.content = '',
    this.createdDate,
    this.relativePath,
    this.modifyDate,
    this.translateContent,
    this.fileName,
    this.timeStamp,
    this.prev,
    this.next,
  });

  final String uid;
  int postId;
  String title;
  String content;
  String? translateContent;
  String? createdDate;
  String? modifyDate;
  String? relativePath;
  String? fileName;
  Timestamp? timeStamp;
  int? prev;
  int? next;

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'title': title,
        'content': content,
        'translateContent': translateContent,
        'createdDate': createdDate,
        'modifyDate': modifyDate,
        'timeStamp': timeStamp,
        'relativePath': relativePath,
        'fileName': fileName,
        'prev': prev,
        'next': next,
      };
}
