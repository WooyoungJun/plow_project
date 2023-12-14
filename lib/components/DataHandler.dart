import 'package:cloud_firestore/cloud_firestore.dart';

import 'UserProvider.dart';

class DataInFireStore {
  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Post>> readPost(String collection, String uid) async {
    var postsRef = FirebaseFirestore.instance.collection(collection);
    var querySnapshot = await postsRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdDate') // 시간 순(오름차 순) -> FireStore Index 설정 필요
        .limit(10)
        .get();
    print('readPost 호출');
    List<Post> posts = querySnapshot.docs.map((doc) {
      return Post(
          postId: doc.id,
          uid: doc.data()['uid'],
          title: doc.data()['title'],
          content: doc.data()['content'],
          createdDate: doc.data()['createdDate']);
    }).toList();
    return posts;
  }

  // post 추가하기
  static Future<Post> addPost(String collection, Post post, String uid) async {
    // 유효성 검사 확인 필요
    var posts = FirebaseFirestore.instance.collection(collection);
    var docRef = await posts.add(post.toMap()); // set -> 아래는 필요 없음
    Post newPost = Post(
      postId: docRef.id,
      uid: post.uid,
      title: post.title,
      content: post.content,
      createdDate: post.createdDate,
    );
    showToast('Post add 완료');
    return newPost;
  }

  // post update
  static Future<void> updatePost(String collection, Post post) async {
    var docRef =
        FirebaseFirestore.instance.collection(collection).doc(post.postId);
    await docRef.update(post.toMap());
    showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(String collection, String postId) async {
    var docRef = FirebaseFirestore.instance.collection(collection).doc(postId);
    await docRef.delete();
    showToast('Post delete 완료');
  }
}

class Post {
  Post(
      {this.postId = '',
      required this.uid,
      this.title = '',
      this.content = '',
      this.createdDate = ''});

  final String postId;
  final String uid;
  String title;
  String content;
  String createdDate;
  String? modifyDate;


  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'title': title,
        'content': content,
        'createdDate': createdDate
      };
}
