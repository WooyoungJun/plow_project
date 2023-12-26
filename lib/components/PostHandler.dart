import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CustomClass/CustomToast.dart';

class PostHandler {
  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Post>> readPost(
      {required String collection, List<String>? uids, int? limit}) async {
    try {
      var postsRef = FirebaseFirestore.instance.collection(collection);
      Query query = postsRef;
      if (uids != null) query = query.where('uid', whereIn: uids);
      QuerySnapshot querySnapshot = await query
          .orderBy('createdDate', descending: true) // 내림차 순(최근 글 위로)
          .limit(limit ?? 10)
          .get();
      List<Post> posts = querySnapshot.docs.map((doc) {
        return Post(
            postId: doc['postId'],
            uid: doc['uid'],
            title: doc['title'],
            content: doc['content'],
            translateContent: doc['translateContent'],
            createdDate: doc['createdDate'],
            modifyDate: doc['modifyDate'],
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

    var posts = FirebaseFirestore.instance.collection(collection);
    var docRef = await posts.add(post.toMap()); // document ID 반환

    post.postId = docRef.id;
    await posts.doc(docRef.id).update({'postId': docRef.id}); // postId update
    CustomToast.showToast('Post add 완료');
    return post;
  }

  // post update
  static Future<void> updatePost(String collection, Post post) async {
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    post.modifyDate = formattedTime;

    var docRef =
        FirebaseFirestore.instance.collection(collection).doc(post.postId);
    await docRef.update(post.toMap());
    CustomToast.showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(String collection, String postId) async {
    var docRef = FirebaseFirestore.instance.collection(collection).doc(postId);
    await docRef.delete();
    CustomToast.showToast('Post delete 완료');
  }
}

class Post {
  Post({
    required this.uid,
    this.postId = '',
    this.title = '',
    this.content = '',
    this.createdDate,
    this.relativePath,
    this.modifyDate,
    this.translateContent,
    this.fileName,
  });

  final String uid;
  String postId;
  String title;
  String content;
  String? translateContent;
  String? createdDate;
  String? modifyDate;
  String? relativePath;
  String? fileName;

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'title': title,
        'content': content,
        'translateContent': translateContent,
        'createdDate': createdDate,
        'modifyDate': modifyDate,
        'relativePath': relativePath,
        'fileName': fileName,
      };
}
