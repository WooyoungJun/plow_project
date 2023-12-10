import 'package:cloud_firestore/cloud_firestore.dart';

class DataInFireStore {
  // uid에 해당하는 유저의 게시글 가져오기
  static Future<List<Todo>> readPost(String uid) async {
    var posts = FirebaseFirestore.instance.collection('BoardList');
    var querySnapshot = await posts
        .where('member_id', isEqualTo: uid)
        .orderBy('created_date') // 시간 순(오름차 순)
        .get();
    print('readPost 호출');
    List<Todo> todos = querySnapshot.docs.map((doc) {
      return Todo(
          postId: doc.id,
          memberId: doc.data()['member_id'],
          title: doc.data()['title'],
          content: doc.data()['content'],
          createdDate: doc.data()['created_date']);
    }).toList();
    return todos;
  }

  // post 추가하기
  static Future<Todo> addPost(String collection, Todo todo, String uid) async {
    // 유효성 검사 확인 필요
    var posts = FirebaseFirestore.instance.collection(collection);
    var docRef = await posts.add(todo.toMap());
    Todo newTodo = Todo(
      postId: docRef.id,
      memberId: todo.memberId,
      title: todo.title,
      content: todo.content,
      createdDate: todo.createdDate,
    );
    return newTodo;
  }

  // post update
  static Future<void> updatePost(String collection, Todo todo) async {
    var docRef =
        FirebaseFirestore.instance.collection(collection).doc(todo.postId);
    await docRef.update(todo.toMap());
  }

  // post 삭제
  static Future<void> deletePost(String collection, String postId) async {
    var docRef = FirebaseFirestore.instance.collection(collection).doc(postId);
    await docRef.delete();
  }
}

class Todo {
  Todo(
      {required this.postId,
      required this.memberId,
      required this.title,
      required this.content,
      required this.createdDate});

  final String postId;
  final String memberId;
  final String title;
  final String content;
  final Timestamp createdDate;

  Map<String, dynamic> toMap() => {
        'id': postId,
        'member_id': memberId,
        'title': title,
        'content': content,
        'created_date': createdDate
      };
}
