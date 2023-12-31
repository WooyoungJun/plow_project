import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CustomClass/CustomToast.dart';

class PostHandler {
  static final FirebaseFirestore _store = FirebaseFirestore.instance;
  static final CollectionReference _boardList = _store.collection('BoardList');
  static final CollectionReference _totalPostCount =
      _store.collection('TotalPostCount');

  static Future<DocumentSnapshot> get totalPostCount async =>
      (await _totalPostCount.doc('count').get());

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
        posts = postList.docs.map((doc) => Post.setDoc(doc)).toList();
      });

      return {'posts': posts, 'totalPosts': totalPosts};
    } catch (err) {
      print(err);
      return {'posts': [], 'totalPosts': 0};
    }
  }

  // uid에 해당하는 유저의 게시글 가져오기
  static Future<Map<String, dynamic>> readPostFriend({
    required List<String> friend,
    required int limit,
    int? last,
    int? refreshGetPost,
  }) async {
    try {
      List<Post> posts = [];
      await _store.runTransaction((transaction) async {
        var query = _boardList
            .where('uid', whereIn: friend)
            .orderBy('postId', descending: true);
        if (last != null) query = query.startAfter([last]);
        var postList = await query.limit(refreshGetPost ?? limit).get();
        posts = postList.docs.map((doc) => Post.setDoc(doc)).toList();
      });
      return {'posts': posts};
    } catch (err) {
      print(err);
      return {'posts': []};
    }
  }

  static Future<void> addPost(Post post, int vc) async {
    try {
      DocumentReference countDoc = _totalPostCount.doc('count');
      DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
      await _store.runTransaction((transaction) async {
        var topPost =
            await _boardList.orderBy('postId', descending: true).limit(1).get();
        var lastPost = await _boardList.orderBy('postId').limit(1).get();
        late int newPostId;

        if (topPost.docs.isEmpty) {
          newPostId = 1;
          transaction.update(countDoc, {
            'count': 1,
            'last': 1,
            'postPageIndex': FieldValue.arrayUnion([1]),
          });
        } else {
          int topPostId = topPost.docs.first['postId'];
          int lastPostId = lastPost.docs.first['postId'];
          newPostId = topPostId + 1;

          var doc = (await transaction.get(countDoc));
          int count = doc['count'];
          List<int> postPageIndex = doc['postPageIndex'].cast<int>();
          int endPage = (count / vc).ceil();

          for (int page = 1; page <= endPage; page++) {
            if (page == 1) {
              postPageIndex[1] = newPostId;
            } else {
              String postId = postPageIndex[page].toString();
              postPageIndex[page] =
                  (await transaction.get(_boardList.doc(postId)))['next'];
            }
          }

          if (count % vc == 0) postPageIndex.add(lastPostId);

          transaction.update(countDoc, {
            'count': FieldValue.increment(1),
            'postPageIndex': postPageIndex
          });

          post.prev = topPostId;
          transaction.update(
              _boardList.doc(topPostId.toString()), {'next': newPostId});
        }

        post.setTime(); // addPost 시간 (timeStamp, DateTime 기록)
        post.postId = newPostId;
        transaction.set(_boardList.doc(newPostId.toString()), post.toMap());
        transaction.update(userCountDoc, {'count': FieldValue.increment(1)});
      });

      CustomToast.showToast('Post add 완료');
    } catch (err) {
      print(err);
      CustomToast.showToast('에러가 발생했습니다.');
    }
  }

  // post update
  static Future<void> updatePost(Post post) async {
    print(post.timeStamp);
    post.updateTime();
    await _store.runTransaction((transaction) async {
      transaction.update(_boardList.doc(post.postId.toString()), post.toMap());
    });
    CustomToast.showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(Post post, int vc) async {
    try {
      DocumentReference countDoc = _totalPostCount.doc('count');
      DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
      // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
      await _store.runTransaction((transaction) async {
        // postPageIndex 변경 -> 당겨오기
        var doc = (await transaction.get(countDoc));
        int last = doc['last'];
        int count = doc['count'];
        List<int> postPageIndex = doc['postPageIndex'].cast<int>();
        int endPage = (count / vc).ceil();
        int start = postPageIndex[1] == post.postId ? 1 : 2;
        for (int page = start; page <= endPage; page++) {
          String postId = postPageIndex[page].toString();
          int? prevPostId = (await transaction
              .get(_boardList.doc(postId)))['prev']; // 마지막 글 제외 prev 항상 존재
          if (prevPostId != null) {
            postPageIndex[page] = prevPostId;
          } else {
            postPageIndex.removeLast();
          }
        }
        transaction.update(countDoc, {
          'postPageIndex': postPageIndex,
          'count': FieldValue.increment(-1)
        });

        // prev, next 연결
        int? next = post.next;
        int? prev = post.prev;
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
        if (post.postId == last) {
          transaction.update(countDoc, {'last': next});
        }
        transaction.update(userCountDoc, {'count': FieldValue.increment(-1)});
        transaction.delete(_boardList.doc(post.postId.toString()));
      });
      CustomToast.showToast('Post delete 완료');
    } catch (err) {
      print(err);
      CustomToast.showToast('에러가 발생했습니다.');
    }
  }
}

class Post {
  Post({
    required this.uid,
    this.postId = -1,
    this.title = '',
    this.content = '',
    this.createdDate,
    this.timeStamp,
    this.modifyDate,
    this.translateContent,
    this.keywordContent,
    this.relativePath,
    this.fileName,
    this.prev,
    this.next,
  });

  final String uid;
  int postId;
  String title;
  String content;
  String? createdDate;
  Timestamp? timeStamp;
  String? modifyDate;
  String? translateContent;
  String? keywordContent;
  String? relativePath;
  String? fileName;
  int? prev;
  int? next;

  void setTime() {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    createdDate = formattedTime;
    timeStamp = Timestamp.now();
  }

  void updateTime() {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    modifyDate = formattedTime;
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'title': title,
        'content': content,
        'createdDate': createdDate,
        'timeStamp': timeStamp,
        'modifyDate': modifyDate,
        'translateContent': translateContent,
        'keywordContent': keywordContent,
        'relativePath': relativePath,
        'fileName': fileName,
        'prev': prev,
        'next': next,
      };

  bool checkPdf({required bool isPdf, String? anotherFileName}){
    if (fileName != null || anotherFileName != null) {
      // 파일이 존재할 때
      ((anotherFileName ?? fileName!).endsWith('.pdf'))
          ? isPdf = true
          : isPdf = false;
    }
    return isPdf;
  }

  static Post setDoc(DocumentSnapshot doc) {
    return Post(
      uid: doc['uid'],
      postId: doc['postId'],
      title: doc['title'],
      content: doc['content'],
      createdDate: doc['createdDate'],
      timeStamp: doc['timeStamp'],
      modifyDate: doc['modifyDate'],
      translateContent: doc['translateContent'],
      relativePath: doc['relativePath'],
      keywordContent: doc['keywordContent'],
      fileName: doc['fileName'],
      prev: doc['prev'],
      next: doc['next'],
    );
  }
}
