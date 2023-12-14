import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'CustomClass/CustomToast.dart';

class DataInFireStore {
  static final Reference storageRef = FirebaseStorage.instance.ref();
  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Post>> readPost(String collection, String uid) async {
    try {
      var postsRef = FirebaseFirestore.instance.collection(collection);
      var querySnapshot = await postsRef
          .where('uid', isEqualTo: uid)
          .orderBy('createdDate') // 시간 순(오름차 순) -> FireStore Index 설정 필요
          .limit(10)
          .get();
      List<Post> posts = querySnapshot.docs.map((doc) {
        return Post(
            postId: doc.id,
            uid: doc.data()['uid'],
            title: doc.data()['title'],
            content: doc.data()['content'],
            createdDate: doc.data()['createdDate']);
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
    var docRef = await posts.add(post.toMap());
    post.postId = docRef.id;
    await posts.doc(docRef.id).set(post.toMap());
    CustomToast.showToast('Post add 완료');
    return post;
  }

  // post update
  static Future<void> updatePost(String collection, Post post) async {
    var docRef =
        FirebaseFirestore.instance.collection(collection).doc(post.postId);
    await docRef.update(post.toMap());
    CustomToast.showToast('Post update 완료');
  }

  // post 삭제
  static Future<void> deletePost(String collection, String postId) async {
    var docRef = FirebaseFirestore.instance.collection(collection).doc(postId);
    var docSnapShot = await docRef.get();
    var photoUrl = docSnapShot['photoUrl'];
    await docRef.delete();
    await deletePhoto(photoUrl);
    CustomToast.showToast('Post delete + Photo delete 완료');
  }

  static Future<void> deletePhoto(String photoUrl) async{
    // Firebase Storage 참조 얻기
    try {
      await storageRef.child(photoUrl).delete();
      print('파일이 성공적으로 삭제되었습니다.');
    } catch (e) {
      print('파일 삭제 중 오류 발생: $e');
    }
  }
}

class Post {
  Post(
      {required this.uid,
      this.postId = '',
      this.title = '',
      this.content = '',
      this.createdDate,
      this.photoUrl});

  final String uid;
  String postId;
  String title;
  String content;
  String? createdDate;
  String? modifyDate;
  String? photoUrl;

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'uid': uid,
        'title': title,
        'content': content,
        'createdDate': createdDate,
        'photoUrl': photoUrl,
      };
}

