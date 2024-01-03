import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:plow_project/components/FileProcessing.dart';
import 'package:plow_project/components/PostHandler.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:plow_project/components/CustomClass/CustomLoadingDialog.dart';

class CustomAlertDialog {
  static Future<void> onSavePressed({
    required BuildContext context,
    required Post? post,
    required Post newPost,
    required Uint8List? fileBytes,
  }) async {
    if (newPost.title.trim().isEmpty) return CustomToast.showToast('제목을 채워주세요');
    bool isCheck = await show(
      context: context,
      text: '''게시글을 저장하시겠습니까?''',
    );
    if (isCheck) {
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
  }

  static Future<void> onDeletePressed({
    required BuildContext context,
    required Post post,
  }) async {
    bool isCheck = await show(
      context: context,
      text: '''정말 삭제하시겠습니까? \n 삭제한 정보는 복구 불가능합니다.''',
    );
    if (isCheck) {
      CustomLoadingDialog.showLoadingDialog(context, '삭제중입니다. \n잠시만 기다리세요');
      await FileProcessing.deleteFile(relativePath: post.relativePath);
      await PostHandler.deletePost(post: post);
      CustomLoadingDialog.pop(context);
      Navigator.pop(context, {'post': null});
    }
  }

  static Future<void> onBackPressed({
    required BuildContext context,
    String? relativePath,
  }) async {
    bool isCheck = await show(
      context: context,
      text: '''정말 뒤로 가시겠습니까? \n 저장하지 않은 정보가 삭제될 수 있습니다.''',
    );
    if (isCheck) {
      CustomLoadingDialog.showLoadingDialog(context, '취소중입니다. \n잠시만 기다리세요');
      await FileProcessing.deleteFile(relativePath: relativePath);
      CustomLoadingDialog.pop(context);
      Navigator.pop(context);
    }
  }

  static Future<Map<String, dynamic>?> onPdfToPngPressed(
      {required BuildContext context,
      required String relativePath,
      required Uint8List fileBytes}) async {
    Map<String, dynamic>? result;
    bool isCheck = await show(
      context: context,
      text:
          '''pdf를 png로 변환하시겠습니까? \n 저장된 pdf파일이 png 파일로 변환됩니다 \n 변환 후 복구 불가능합니다''',
    );
    if (isCheck) {
      CustomLoadingDialog.showLoadingDialog(context, '이미지 변환중입니다');
      result = await FileProcessing.pdfToPng(fileBytes: fileBytes);
      CustomLoadingDialog.pop(context);
    }
    return result;
  }

  static Future<void> showFriendCheck({
    required BuildContext context,
    required UserProvider userProvider,
    required String text,
    TextEditingController? controller,
    String? friendEmail,
  }) async {
    bool isCheck = await show(context: context, text: '정말 $text하시겠습니까?');
    if (isCheck) {
      CustomLoadingDialog.showLoadingDialog(context, '$text중입니다. \n잠시만 기다리세요');
      if (text == '삭제') {
        await userProvider.deleteFriend(friendEmail!);
      } else {
        await userProvider.addFriend(controller!.text);
        controller.clear();
      }
      await userProvider.getStatus();
      CustomLoadingDialog.pop(context);
    }
  }

  static Future<bool> show({
    required BuildContext context,
    required String text,
  }) async {
    bool isCheck = false;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고', textAlign: TextAlign.center),
          titleTextStyle: TextStyle(fontSize: 16.0, color: Colors.black),
          content: IntrinsicHeight(
            child: Text(text, textAlign: TextAlign.center),
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
                  onPressed: () {
                    isCheck = true;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
    return isCheck;
  }
}
