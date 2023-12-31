import 'package:flutter/material.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';

class CustomAlertDialog {
  static Future<void> onSavePressed(BuildContext context, TextEditingController titleController, ) async {
    if (titleController.text.trim().isEmpty) {
      return CustomToast.showToast('제목은 비어질 수 없습니다');
    }

    CustomLoadingDialog.showLoadingDialog(context, '업로드 중입니다. 잠시만 기다리세요');
    // Map<String, dynamic>? result = await FileProcessing.transitionToStorage(
    //     relativePath: relativePath, fileName: fileName, fileBytes: fileBytes);
    // if (result != null) {
    //   relativePath = result['relativePath'];
    //   fileName = result['fileName'];
    // }
    // Post newPost = Post(
    //   uid: userProvider.uid!,
    //   title: _titleController.text,
    //   content: _contentController.text,
    //   translateContent: _translateController.text,
    //   relativePath: relativePath,
    //   fileName: fileName,
    // );
    // await PostHandler.addPost(post: newPost);
    CustomLoadingDialog.pop(context);
    Navigator.pop(context, {'upload': true});
  }

  static Future<void> onDeletePressed(BuildContext context, Post post) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('정말 삭제하시겠습니까?'),
              Text('삭제한 정보는 복구 불가능합니다.'),
            ],
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
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('정말 뒤로 가시겠습니까?'),
              Text('저장하지 않은 정보가 삭제될 수 있습니다.'),
            ],
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
