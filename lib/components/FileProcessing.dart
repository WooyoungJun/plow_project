import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'CustomClass/CustomToast.dart';
import 'package:http/http.dart' as http;

class FileProcessing {
  static final FirebaseStorage _storageRef = FirebaseStorage.instance;

  // image 가져오기
  static Future<Map<String, String>?> getFile() async {
    try {
      const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (fileResult != null && fileResult.files.isNotEmpty) {
        String fileExtension = fileResult.files.first.extension!.toLowerCase();
        File pickedFile = File(fileResult.files.first.path!);
        Map<String, String>? result =
            await uploadFileToTmp(pickedFile, fileExtension);
        return result;
      } else {
        CustomToast.showToast('파일을 선택해주세요');
      }
    } catch (err) {
      print('파일 선택 오류: $err');
    }
    return null;
  }

  static Future<Map<String, String>?> getImage(
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
              await uploadFileToTmp(pickedFile, fileExtension);
          return result;
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

  static Future<Map<String, String>?> uploadFileToTmp(
      File pickedFile, String fileExtension) async {
    try {
      String fileName = randomString(fileExtension);
      String relativePath = 'uploads/tmp/$fileName';
      var storageReference = _storageRef.ref().child(relativePath);
      TaskSnapshot snapShot = await storageReference.putFile(pickedFile);
      String downloadURL = await snapShot.ref.getDownloadURL();

      CustomToast.showToast('이미지 업로드 완료');
      return {
        'downloadURL': downloadURL,
        'relativePath': relativePath,
        'fileName': fileName,
      };
    } catch (err) {
      print('업로드 오류: $err');
      CustomToast.showToast('이미지 업로드 오류');
    }
    return null;
  }

  static Future<Map<String, String>?> transitionToStorage(
      String relativePath, String fileName) async {
    try {
      String newRelativePath = 'uploads/saved/$fileName}';
      Reference sourceReference = _storageRef.ref(relativePath);
      Reference destinationReference = _storageRef.ref(newRelativePath);
      Uint8List? sourceData = await sourceReference.getData();
      TaskSnapshot copyTask = await destinationReference.putData(sourceData!);
      if (copyTask.state == TaskState.success) {
        await deleteFile(relativePath);
        print('파일 이동 성공');
      } else {
        print('파일 이동 실패: 복사 중 문제 발생');
      }
      String downloadURL = await copyTask.ref.getDownloadURL();
      CustomToast.showToast('이미지 업로드 완료');
      return {
        'downloadURL': downloadURL,
        'relativePath': newRelativePath,
        'fileName': fileName,
      };
    } catch (err) {
      print('업로드 오류: $err');
      CustomToast.showToast('이미지 업로드 오류');
    }
    return null;
  }

  static Future<void> deleteFile(String relativePath) async {
    // Firebase Storage 참조 얻기
    try {
      await _storageRef.ref().child(relativePath).delete();
      print('업로드 된 파일이 성공적으로 삭제되었습니다.');
      CustomToast.showToast('Photo delete 완료');
    } catch (e, stackTrace) {
      print('파일 삭제 중 오류 발생: $e\n$stackTrace');
      CustomToast.showToast('Photo delete 에러 $e');
    }
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
  static String randomString(String fileExtension) {
    String formattedDateTime = DateTime.now().millisecondsSinceEpoch.toString();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    String name = String.fromCharCodes(
      Iterable.generate(
          10, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return '${formattedDateTime}_${name}_$fileExtension';
  }
}
