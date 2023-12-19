import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'CustomClass/CustomToast.dart';

class PostHandler {
  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Post>> readPost(String collection, String uid) async {
    try {
      print('readPost');
      var postsRef = FirebaseFirestore.instance.collection(collection);
      var querySnapshot = await postsRef
          .where('uid', isEqualTo: uid)
          .orderBy('createdDate',
              descending: true) // 시간 순(오름차 순) -> FireStore Index 설정 필요
          .limit(10)
          .get();
      List<Post> posts = querySnapshot.docs.map((doc) {
        return Post(
            postId: doc.id,
            uid: doc.data()['uid'],
            title: doc.data()['title'],
            content: doc.data()['content'],
            translateContent: doc.data()['translateContent'],
            createdDate: doc.data()['createdDate'],
            modifyDate: doc.data()['modifyDate'],
            relativePath: doc.data()['relativePath'],
            downloadURL: doc.data()['downloadURL'],
            fileName: doc.data()['fileName']);
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
  static Future<void> deletePost(
      String collection, String postId, String? relativePath) async {
    var docRef = FirebaseFirestore.instance.collection(collection).doc(postId);
    if (relativePath != null) {
      await FileProcessing.deleteFile(relativePath);
    }
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
    this.downloadURL,
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
  String? downloadURL;
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
        'downloadURL': downloadURL,
        'fileName': fileName,
      };
}
