import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plow_project/components/ConstSet.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';

class PostHandler {
  static final FirebaseFirestore _store = FirebaseFirestore.instance;
  static final CollectionReference _boardList = _store.collection('BoardList');
  static final CollectionReference _totalPostCount =
      _store.collection('TotalPostCount');
  static final CollectionReference _userInfo = _store.collection('UserInfo');
  static final CollectionReference _apiKey = _store.collection('APIKey');

  static Future<String> get openApiKey async =>
      (await _apiKey.doc('openAI_API_Key').get())['key'];

  static Future<DocumentSnapshot> get totalPostCount async =>
      (await _totalPostCount.doc('count').get());

  static Future<Map<String, dynamic>> readPostAll({required int page}) async {
    try {
      List<Post> posts = [];
      int totalPosts = 0;
      await _store.runTransaction((transaction) async {
        var doc = (await transaction.get(_totalPostCount.doc('count')));
        List<int> postPageIndex = doc['postPageIndex'].cast<int>();
        if (postPageIndex.length == 1) return {'posts': [], 'totalPosts': 0};
        totalPosts = doc['count'];
        page = page < postPageIndex.length ? page : 1;
        // 글 삭제 후 돌아올 때 현재 페이지가 존재하지 않으면 1페이지로 돌아가기
        int postId = postPageIndex[page];
        var postList = await _boardList
            .orderBy('postId', descending: true)
            .startAt([postId])
            .limit(ConstSet.limit)
            .get();
        posts = postList.docs.map((doc) => Post.setDoc(doc)).toList();
      });

      return {'posts': posts, 'totalPosts': totalPosts};
    } catch (err) {
      print(err);
      return {'posts': [], 'totalPosts': 0};
    }
  }

  static Future<Map<String, dynamic>?> readPostFriend({
    required List<String> friend,
    int? last,
  }) async {
    try {
      List<Post> posts = [];
      int docLast = (await totalPostCount)['last'];
      if (last == docLast) return null;
      await _store.runTransaction((transaction) async {
        var query = _boardList
            .where('uid', whereIn: friend)
            .orderBy('postId', descending: true);
        if (last != null) query = query.startAfter([last]);
        // 포스트 더 불러오는 경우
        var postList = await query.limit(ConstSet.limit).get();
        posts = postList.docs.map((doc) => Post.setDoc(doc)).toList();
      });
      return {'posts': posts};
    } catch (err) {
      print(err);
      return null;
    }
  }

  static Future<void> addPost({required Post post}) async {
    try {
      DocumentReference countDoc = _totalPostCount.doc('count');
      DocumentReference userDoc = _userInfo.doc(post.uid);

      // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
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
            'postPageIndex': [-1, 1],
          });
        } else {
          int topPostId = topPost.docs.first['postId'];
          int lastPostId = lastPost.docs.first['postId'];
          newPostId = topPostId + 1;
          // 새 PostId = 가장 최근 postId + 1

          var doc = (await transaction.get(countDoc));
          int count = doc['count'];
          List<int> postPageIndex = doc['postPageIndex'].cast<int>();
          int endPage = (count / ConstSet.visibleCount).ceil();
          postPageIndex[1] = newPostId;
          for (int page = 2; page <= endPage; page++) {
            String postId = postPageIndex[page].toString();
            postPageIndex[page] =
                (await transaction.get(_boardList.doc(postId)))['next'];
          }
          // 각 페이지마다 최상위 글 postId 업데이트 -> 이전 post들의 다음 postId

          if (count % ConstSet.visibleCount == 0) postPageIndex.add(lastPostId);
          // visibleCount마다 새로운 페이지 인덱스 추가

          transaction.update(countDoc, {
            'count': FieldValue.increment(1),
            'postPageIndex': postPageIndex
          });

          post.prev = topPostId;
          transaction.update(
              _boardList.doc(topPostId.toString()), {'next': newPostId});
          // 가장 최근 post와 새로 추가하는 post 연결

          doc = await transaction.get(userDoc);
          var dailyQuestStatus = doc['dailyQuestStatus'];
          dailyQuestStatus['postCount'] += 1;
          transaction.update(userDoc, {'dailyQuestStatus': dailyQuestStatus});
        }

        post.setTime(); // post 추가 시간 (timeStamp, DateTime 기록)
        post.postId = newPostId; // postId 설정
        transaction.set(_boardList.doc(newPostId.toString()), post.toMap());
        transaction.update(userDoc, {'count': FieldValue.increment(1)});
      });

      CustomToast.showToast('Post add 완료');
    } catch (err) {
      print(err);
      CustomToast.showToast('에러가 발생했습니다.');
    }
  }

  static Future<void> updatePost({required Post post}) async {
    await _store.runTransaction((transaction) async {
      post.updateTime();
      transaction.update(_boardList.doc(post.postId.toString()), post.toMap());
    });
    CustomToast.showToast('Post update 완료');
  }

  static Future<void> deletePost({required Post post}) async {
    try {
      DocumentReference countDoc = _totalPostCount.doc('count');
      DocumentReference userDoc = _userInfo.doc(post.uid);
      // 트랜잭션 실행 -> 데이터 경합 방지 및 자동 트랜잭션 재실행
      await _store.runTransaction((transaction) async {
        // postPageIndex 변경 -> 당겨오기
        var doc = (await transaction.get(countDoc));
        int last = doc['last'];
        int count = doc['count'];
        List<int> postPageIndex = doc['postPageIndex'].cast<int>();
        int endPage = (count / ConstSet.visibleCount).ceil();
        for (int page = 1; page <= endPage; page++) {
          if (postPageIndex[page] > post.postId) continue;
          // 현재 page의 최상위 postId가 더 크면 이번 페이지는 안바꿔도 됨

          String postId = postPageIndex[page].toString();
          int? prevPostId = (await transaction
              .get(_boardList.doc(postId)))['prev']; // 마지막 글 제외 prev 항상 존재
          if (prevPostId != null) {
            postPageIndex[page] = prevPostId;
          } else {
            postPageIndex.removeLast();
          }
        }

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
        if (post.postId == last) transaction.update(countDoc, {'last': next});
        // 마지막 글의 경우, 마지막 글 가리키는 포인터 last 변경 필요 -> next postId로 변경

        transaction.update(userDoc, {'count': FieldValue.increment(-1)});
        transaction.update(countDoc, {
          'postPageIndex': postPageIndex,
          'count': FieldValue.increment(-1),
        });
        transaction.delete(_boardList.doc(post.postId.toString()));
        // user count, total count 수정
        // postPageIndex 업데이트 반영
        // post 삭제
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
    this.translateContent = '',
    this.keywordContent = '',
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
  String translateContent;
  String keywordContent;
  String? relativePath;
  String? fileName;
  int? prev;
  int? next;

  @override
  bool operator ==(Object other) =>
      // title, content, translate, keyword, relativePath, fileName 비교
      identical(this, other) ||
      other is Post &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          content == other.content &&
          translateContent == other.translateContent &&
          keywordContent == other.keywordContent &&
          relativePath == other.relativePath &&
          fileName == other.fileName;

  @override
  int get hashCode =>
      title.hashCode ^
      content.hashCode ^
      translateContent.hashCode ^
      keywordContent.hashCode ^
      relativePath.hashCode ^
      fileName.hashCode;

  // 복사 생성자
  Post.copy(Post original)
      : uid = original.uid,
        postId = original.postId,
        title = original.title,
        content = original.content,
        createdDate = original.createdDate,
        timeStamp = original.timeStamp,
        modifyDate = original.modifyDate,
        translateContent = original.translateContent,
        keywordContent = original.keywordContent,
        relativePath = original.relativePath,
        fileName = original.fileName,
        prev = original.prev,
        next = original.next;

  void setTime() {
    // DateTime, TimeStamp 기반 createTime Setting
    DateTime koreaTime = DateTime.now().toUtc().add(Duration(hours: 9));
    String formattedTime = DateFormat.yMd().add_jms().format(koreaTime);
    createdDate = formattedTime;
    timeStamp = Timestamp.now();
  }

  void updateTime() {
    // DateTime 기반 modifyDate Setting
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

  // post에 업로드한 파일이 pdf인지 확인하는 메소드
  bool checkPdf() {
    if (fileName == null) return false;
    return fileName!.endsWith('.pdf') ? true : false;
  }

  // doc 가져와서 Post로 만들어주는 메소드
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
      keywordContent: doc['keywordContent'],
      relativePath: doc['relativePath'],
      fileName: doc['fileName'],
      prev: doc['prev'],
      next: doc['next'],
    );
  }
}
