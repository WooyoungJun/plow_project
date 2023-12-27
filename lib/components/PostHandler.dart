import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CustomClass/CustomToast.dart';

class PostHandler {
  // final CollectionReference _boardList =
  //     FirebaseFirestore.instance.collection('BoardList');

  static Future<int> get totalPostCount async =>
      (await FirebaseFirestore.instance
          .collection('TotalPostCount')
          .doc('count')
          .get())['count'];

  static Future<int> totalFriendPostCount(List<String> friend) async {
    int totalCount = 0;
    for (String friendEmail in friend) {
      DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance
          .collection('TotalPostCount')
          .doc(friendEmail)
          .get();
      if (friendSnapshot.exists) totalCount += friendSnapshot['count'] as int;
    }
    return totalCount;
  }

  static Future<void> setUserPostCount(String userEmail) async {
    await FirebaseFirestore.instance
        .collection('TotalPostCount')
        .doc(userEmail)
        .set({'count': 0});
  }

  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Post>> readPost(
      {required String collection,
      List<String>? uids,
      required int start,
      required int end,
      required int limit}) async {
    try {
      var postsRef = FirebaseFirestore.instance.collection(collection);
      Query query = postsRef;
      if (uids != null) query = query.where('uid', whereIn: uids);
      QuerySnapshot querySnapshot = await query
          .orderBy('postId')
          .startAt([start])
          .endBefore([end])
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
  static Future<Post> addPost(String collection, Post post) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.createdDate = formattedTime;
    post.timeStamp = Timestamp.now();
    late int postIndex;
    // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재 실행 활용
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      postIndex = (await transaction.get(FirebaseFirestore.instance
              .collection('TotalPostCount')
              .doc('count')))
          .data()!['count'];
      transaction.update(
          FirebaseFirestore.instance.collection('TotalPostCount').doc('count'),
          {'count': postIndex + 1});
      transaction.update(
          FirebaseFirestore.instance.collection('TotalPostCount').doc(post.uid),
          {'count': FieldValue.increment(1)});
    });
    post.postId = postIndex;
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(postIndex.toString())
        .set(post.toMap());
    CustomToast.showToast('Post add 완료');
    return post;
  }

  // post update
  static Future<void> updatePost(String collection, Post post) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.modifyDate = formattedTime;

    var posts = FirebaseFirestore.instance.collection(collection);
    await posts.doc(post.postId.toString()).update(post.toMap());
    CustomToast.showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(String collection, Post post) async {
    var docRef =
        FirebaseFirestore.instance.collection(collection).doc(post.postId.toString());
    await docRef.delete();
    await FirebaseFirestore.instance
        .collection('TotalPostCount')
        .doc('count')
        .update({'count': FieldValue.increment(-1)});
    await FirebaseFirestore.instance
        .collection('TotalPostCount')
        .doc(post.uid)
        .update({'count': FieldValue.increment(-1)});
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
      };
}
