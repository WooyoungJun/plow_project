import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';

class CustomAlertDialog {
  static Future<void> onSavePressed({
    required BuildContext context,
    required Post? post,
    required Post newPost,
    required Uint8List? fileBytes,
  }) async {
    if (newPost.title.trim().isEmpty) return CustomToast.showToast('제목을 채워주세요');
    if (post != newPost) {
      // title, content, translate, keyword, relativePath, fileName 비교
      CustomLoadingDialog.showLoadingDialog(context, '업로드 중입니다. 잠시만 기다리세요');
      Map<String, dynamic>? result = await FileProcessing.transitionToStorage(
        relativePath: newPost.relativePath,
        fileName: newPost.fileName,
        fileBytes: fileBytes,
      );
      if (result != null) {
        FileProcessing.deleteFile(relativePath: post?.relativePath);
        newPost.relativePath = result['relativePath'];
        newPost.fileName = result['fileName'];
      }
      if (post == null) {
        // post add
        await PostHandler.addPost(post: newPost);
      } else {
        // post update
        await PostHandler.updatePost(post: newPost);
      }
      CustomLoadingDialog.pop(context);
      Navigator.pop(context, {'save': true});
    } else {
      CustomToast.showToast('변경 사항이 없습니다!');
    }
  }

  static Future<void> onDeletePressed(BuildContext context, Post post) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          content: SizedBox(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('정말 삭제하시겠습니까?'),
                Text('삭제한 정보는 복구 불가능합니다.'),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  child: Text('취소'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text('확인'),
                  onPressed: () async {
                    // 확인 버튼이 눌렸을 때, 게시물 삭제 수행
                    CustomLoadingDialog.showLoadingDialog(
                        context, '삭제중입니다. \n잠시만 기다리세요');
                    await FileProcessing.deleteFile(
                        relativePath: post.relativePath);
                    await PostHandler.deletePost(post: post);
                    CustomLoadingDialog.pop(context);
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(context, {'post': null});
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> onBackPressed(
      BuildContext context, String? relativePath) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          content: SizedBox(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('정말 뒤로 가시겠습니까?'),
                Text('저장하지 않은 정보가 삭제될 수 있습니다.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () async {
                CustomLoadingDialog.showLoadingDialog(
                    context, '취소중입니다. \n잠시만 기다리세요');
                await FileProcessing.deleteFile(relativePath: relativePath);
                CustomLoadingDialog.pop(context);
                Navigator.pop(context);
                Navigator.pushReplacementNamed(
                    context, '/HomeView'); // 그냥 홈으로 이동
              },
            ),
          ],
        );
      },
    );
  }
}
