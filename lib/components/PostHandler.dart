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
  static Future<List<Post>> readPostAll(
      {required int totalPosts, required int page, required int limit}) async {
    try {
      var docRef = await _totalPostCount.doc('count').get();
      List<int> postPageIndex = docRef['postPageIndex'].cast<int>();
      int postIndex = page == 1
          ? totalPosts
          : postPageIndex[postPageIndex.length - (page - 1)];
      print(postIndex);
      QuerySnapshot querySnapshot = await _boardList
          .orderBy('postId', descending: true)
          .startAt([postIndex])
          .limit(limit)
          .get();
      List<Post> posts = querySnapshot.docs.map((doc) {
        return Post(
            postId: doc['postId'],
            uid: doc['uid'],
            title: doc['title'],
            content: doc['content'],
            createdDate: doc['createdDate'],
            modifyDate: doc['modifyDate'],
            translateContent: doc['translateContent'],
            relativePath: doc['relativePath'],
            fileName: doc['fileName']);
      }).toList();
      return posts;
    } catch (err) {
      print(err);
      return [];
    }
  }

  // post 추가하기
  static Future<void> addPost(int startPage, int endPage, Post post) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.createdDate = formattedTime;
    post.timeStamp = Timestamp.now();

    DocumentReference countDoc = _totalPostCount.doc('count');
    DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
    late int postIndex;
    late int count;
    // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
    await _store.runTransaction((transaction) async {
      var data = (await transaction.get(countDoc));
      postIndex = data['postIndex'];
      count = data['count'];

      // postPageIndex 변경
      List<int> postPageIndex =
          (await transaction.get(countDoc))['postPageIndex'].cast<int>();
      for (int pageIndex = startPage; pageIndex <= endPage; pageIndex++) {
        if (pageIndex == 1) {
          postPageIndex[0] = count + 1;
          continue;
        }
        String postId = postPageIndex[pageIndex - 1].toString();
        int nextPostId =
            (await transaction.get(_boardList.doc(postId)))['next'];
        postPageIndex[pageIndex - 1] = nextPostId;
      }

      // countDoc, userCountDoc 값 증가
      transaction.update(countDoc, {
        'count': FieldValue.increment(1),
        'postIndex': FieldValue.increment(1),
        'postPageIndex':
            FieldValue.arrayUnion(count % 3 == 0 ? [postIndex] : [])
      });
      transaction.update(userCountDoc, {'count': FieldValue.increment(1)});
      post.postId = postIndex;
      transaction.set(_boardList.doc(postIndex.toString()), post.toMap());
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
  static Future<void> deletePost(int startPage, int endPage, Post post) async {
    DocumentReference countDoc = _totalPostCount.doc('count');
    DocumentReference userCountDoc = _totalPostCount.doc(post.uid);
    late int count;
    late List<int> postPageIndex;
    // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
    await _store.runTransaction((transaction) async {
      // postPageIndex 변경
      postPageIndex = (await transaction.get(countDoc))['postPageIndex'];
      for (int pageIndex = startPage; pageIndex <= endPage; pageIndex++) {
        String postId = postPageIndex[pageIndex - 1].toString();
        int prevPostId =
            (await transaction.get(_boardList.doc(postId)))['prev'];
        postPageIndex[pageIndex - 1] = prevPostId;
      }
      if (post.next != null && post.prev != null) {
        // 앞 뒤 존재
        transaction
            .update(_boardList.doc(post.next.toString()), {'prev': post.prev});
        transaction
            .update(_boardList.doc(post.prev.toString()), {'next': post.next});
      } else if (post.prev != null) {
        // 맨 마지막 글
        transaction
            .update(_boardList.doc(post.prev.toString()), {'next': post.next});
      } else if (post.next != null) {
        // 맨 처음 글
        transaction
            .update(_boardList.doc(post.next.toString()), {'prev': post.prev});
      }

      transaction.update(countDoc,
          {'postPageIndex': postPageIndex, 'count': FieldValue.increment(-1)});

      count = (await transaction.get(countDoc))['count'];
      int curPostId = post.postId;
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
