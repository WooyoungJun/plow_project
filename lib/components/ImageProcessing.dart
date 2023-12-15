import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'CustomClass/CustomToast.dart';

class ImageProcessing {
  // image 가져오기
  static Future<Map<String, dynamic>?> getImage(
      ImagePicker picker, ImageSource imageSource) async {
    try {
      const List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
      var imageFile = await picker.pickImage(source: imageSource);

      if (imageFile != null) {
        // jpg, jpeg, png만 인식
        var fileExtension = imageFile.path.split('.').last.toLowerCase();
        if (imageExtensions.contains(fileExtension)) {
          fileExtension = fileExtension;
          File pickedFile = File(imageFile.path);
          return {'fileExtension': fileExtension, 'pickedFile': pickedFile};
        } else {
          // 이미지 파일이 아닌 경우 처리
          CustomToast.showToast('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print(fileExtension);
        }
      }
    } catch (err) {
      print('이미지 선택 오류: $err');
    }
    return null;
  }

  static Widget imageOrText({File? pickedFile, String? photoUrl}) {
    if (pickedFile != null) { // pickedFile를 먼저 확인
      return Image.file(pickedFile, fit: BoxFit.cover, width: double.infinity);
    } else if (photoUrl != null) {
      return Image.network(photoUrl);
    } else {
      return Container();
    }
  }

  static Future<String?> uploadFile(
      File? pickedFile, String? fileExtension) async {
    if (pickedFile != null) {
      try {
        // 밀리초 -> 거의 유일하게 저장 가능
        String formattedDateTime =
            DateTime.now().millisecondsSinceEpoch.toString();
        var storageReference = FirebaseStorage.instance.ref().child(
            'uploads/${formattedDateTime}_${randomString(6)}_$fileExtension');
        var uploadTask = storageReference.putFile(pickedFile);

        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
        CustomToast.showToast('업로드 완료');

        return await taskSnapshot.ref.getDownloadURL(); // 업로드된 파일의 다운로드 URL
      } catch (err) {
        print('업로드 오류: $err');
        CustomToast.showToast('이미지 업로드 오류');
      }
    } else {
      CustomToast.showToast('이미지를 선택하세요');
    }
    return null;
  }

  static Future<String?> fileToText(String? photoUrl) async {
    if (photoUrl != null) {
      // 업로드 완료 후 텍스트 변환 가능
      String result = '';
      // setState(() => contentController.text = result);
      return result;
    } else {
      CustomToast.showToast('이미지를 업로드 하세요.');
    }
    return null;
  }
  
  // 랜덤한 문자열 생성
  static String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}
