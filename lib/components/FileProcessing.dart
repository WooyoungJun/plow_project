import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'CustomClass/CustomToast.dart';
import 'package:http/http.dart' as http;

class FileProcessing {
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
          File pickedFile = File(imageFile.path);
          Map<String, String>? result =
              await uploadFile(pickedFile, fileExtension);
          if (result != null) {
            return {
              'downloadURL': result['downloadURL'],
              'relativePath': result['relativePath']
            };
          }
        } else {
          // 이미지 파일이 아닌 경우 처리
          CustomToast.showToast('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print(fileExtension);
        }
      } else {
        CustomToast.showToast('파일을 선택해주세요');
      }
    } catch (err) {
      print('이미지 선택 오류: $err');
    }
    return null;
  }

  static Future<Map<String, String>?> uploadFile(
      File? pickedFile, String? fileExtension) async {
    if (pickedFile != null) {
      try {
        // 밀리초 -> 거의 유일하게 저장 가능
        String formattedDateTime =
            DateTime.now().millisecondsSinceEpoch.toString();
        String relativePath =
            'uploads/${formattedDateTime}_${randomString(6)}_$fileExtension';
        var storageReference =
            FirebaseStorage.instance.ref().child(relativePath);
        TaskSnapshot snapShot = await storageReference.putFile(pickedFile);
        String downloadURL = await snapShot.ref.getDownloadURL();

        CustomToast.showToast('이미지 업로드 완료');
        return {'downloadURL': downloadURL, 'relativePath': relativePath};
      } catch (err) {
        print('업로드 오류: $err');
        CustomToast.showToast('이미지 업로드 오류');
      }
    } else {
      CustomToast.showToast('이미지를 선택하세요');
    }
    return null;
  }

  static Widget imageOrText({String? downloadURL}) {
    if (downloadURL != null) {
      return Image.network(downloadURL);
    } else {
      return Container();
    }
  }

  static Future<String?> fileToText(String? downloadURL) async {
    if (downloadURL != null) {
      try {
        final response = await http.post(
            Uri.parse('http://www.wooyoung-project.kro.kr/textTranslation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imageUrl': downloadURL}));
        if (response.statusCode == 200) {
          String extractedText = response.body;
          print(extractedText);
          CustomToast.showToast('텍스트 변환 성공');
          return extractedText;
        } else {
          print(
              '서버 응답 실패. Status code: ${response.statusCode}, Error: ${response.body}');
          CustomToast.showToast('텍스트 변환 실패');
        }
      } catch (err) {
        print('에러 발생: $err');
      }
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
