import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plow_project/components/const/Size.dart';
import 'package:intl/intl.dart';
import '../../components/AppBarTitle.dart';
import '../../components/CustomClass/CustomToast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PhotoUploadView extends StatefulWidget {
  @override
  State<PhotoUploadView> createState() => _HomeViewState();
}

class _HomeViewState extends State<PhotoUploadView> {
  final _picker = ImagePicker();
  List<String> imageExtensions = ['jpg', 'jpeg', 'png'];
  File? _pickedFile;
  String? _fileExtension;
  String? _fileStorageRef;

  Widget imageOrText(File? pickedFile) {
    if (pickedFile != null) {
      return Image.file(pickedFile, fit: BoxFit.cover, width: double.infinity);
    } else {
      return SizedBox(
        width: double.infinity,
        child: Center(
          child: Text('이미지를 선택하세요.', style: TextStyle(fontSize: 16.0)),
        ),
      );
    }
  }

  Future<void> getImage(ImageSource imageSource) async {
    try {
      XFile? pickedFile = await _picker.pickImage(source: imageSource);

      if (pickedFile != null) {
        // jpg, jpeg, png만 인식
        var fileExtension = pickedFile.path.split('.').last.toLowerCase();
        if (imageExtensions.contains(fileExtension)) {
          setState(() {
            _fileExtension = fileExtension;
            _pickedFile = File(pickedFile.path);
          });
        } else {
          // 이미지 파일이 아닌 경우 처리
          print('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print(fileExtension);
        }
      }
    } catch (err) {
      print('이미지 선택 오류: $err');
    }
  }

  Future<void> getFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        String filePath = result.files.single.path!;
        String fileExtension = result.files.single.extension ?? '';

        // 파일 유형에 따라 처리
        if (imageExtensions.contains(fileExtension.toLowerCase())) {
          // 이미지 파일인 경우
          setState(() {
            _fileExtension = fileExtension.toLowerCase();
            _pickedFile = File(filePath);
          });
        } else if (fileExtension.toLowerCase() == 'pdf') {
          // PDF 파일인 경우
          setState(() {
            _fileExtension = 'pdf';
            _pickedFile = File(filePath);
          });
        } else {
          // 다른 파일 유형인 경우
          print('선택된 파일은 지원되지 않는 유형입니다.');
          print(fileExtension);
        }
      }
    } catch (err) {
      print('파일 선택 오류: $err');
    }
  }

  Future<void> uploadFile() async {
    if (_pickedFile != null) {
      try {
        String formattedDateTime =
            DateFormat('yyyy_MM_dd_HH_mm_ss').format(DateTime.now());
        var storageReference = FirebaseStorage.instance
            .ref()
            .child('uploads/$formattedDateTime.$_fileExtension');
        var uploadTask = storageReference.putFile(_pickedFile!);

        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
        CustomToast.showToast('업로드 완료');

        _fileStorageRef =
            await taskSnapshot.ref.getDownloadURL(); // 업로드된 파일의 다운로드 URL
      } catch (err) {
        print('업로드 오류: $err');
      }
    } else {
      CustomToast.showToast('이미지를 선택하세요');
    }
  }

  Future<void> fileToText() async {
    if (_fileStorageRef != null) {
      try {
        final response = await http.post(
            Uri.parse('http://www.wooyoung-project.kro.kr/textTranslation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'imageUrl': _fileStorageRef}));
        if (response.statusCode == 200) {
          String extractedText = response.body;
          print(extractedText);
          CustomToast.showToast('텍스트 변환 성공');
        } else {
          print('서버 응답 실패. Status code: ${response.statusCode}, Error: ${response.body}');
          CustomToast.showToast('텍스트 변환 실패');
        }
      } catch (err) {
        print('에러 발생: $err');
      }
    } else {
      CustomToast.showToast('이미지를 업로드 하세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: '자유 게시판'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: imageOrText(_pickedFile),
            ),
            SizedBox(height: largeGap),
            ElevatedButton(
              onPressed: () => getImage(ImageSource.gallery),
              child: Text('갤러리에서 이미지 선택'),
            ),
            ElevatedButton(
              onPressed: () => getImage(ImageSource.camera),
              child: Text('카메라로 촬영하기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadFile,
              child: Text('이미지 업로드'),
            ),
            ElevatedButton(
              onPressed: fileToText,
              child: Text('텍스트 변환'),
            ),
          ],
        ),
      ),
    );
  }
}
