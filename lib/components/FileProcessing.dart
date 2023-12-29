import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

// import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'package:image/image.dart' as imglib;

import 'CustomClass/CustomToast.dart';

class FileProcessing {
  static final FirebaseStorage _storageRef = FirebaseStorage.instance;
  static final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static Future<Uint8List?> loadFileFromStorage(String? relativePath) async {
    if (relativePath != null) {
      try {
        Uint8List? fileBytes =
            await _storageRef.ref().child(relativePath).getData();
        return fileBytes;
      } catch (err) {
        print('이미지 가져오는 중에 에러 : $err');
      }
    }
    return null;
  }

  // image 가져오기
  static Future<Map<String, dynamic>?> getFile() async {
    try {
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        withData: true, // byte정보 포함
      );

      if (fileResult != null && fileResult.files.isNotEmpty) {
        String fileExtension = fileResult.files.first.extension!.toLowerCase();
        Uint8List fileBytes = fileResult.files.first.bytes!;
        return await uploadFileToTmp(
            fileResult.files.first.path!, fileExtension, fileBytes);
      } else {
        CustomToast.showToast('파일을 선택해주세요');
      }
    } catch (err) {
      print('파일 선택 오류: $err');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getImage(
      ImagePicker picker, ImageSource imageSource) async {
    try {
      XFile? imageFile = await picker.pickImage(source: imageSource);

      if (imageFile != null) {
        String fileExtension = imageFile.path.split('.').last.toLowerCase();
        if (allowedExtensions.contains(fileExtension)) {
          Uint8List fileBytes = await imageFile.readAsBytes();
          return await uploadFileToTmp(
              imageFile.path, fileExtension, fileBytes);
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

  static Future<Map<String, dynamic>?> uploadFileToTmp(
      String internalPath, String fileExtension, Uint8List fileBytes) async {
    try {
      String fileName = randomString(fileExtension);
      String relativePath = 'uploads/tmp/$fileName';
      var storageReference = _storageRef.ref().child(relativePath);
      await storageReference.putData(fileBytes);
      CustomToast.showToast('이미지 업로드 완료');
      return {
        'internalPath': internalPath,
        'relativePath': relativePath,
        'fileName': fileName,
        'fileBytes': fileBytes,
      };
    } catch (err) {
      print('업로드 오류: $err');
      CustomToast.showToast('이미지 업로드 오류');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> transitionToStorage(
    String? relativePath,
    String? fileName,
    Uint8List? fileBytes,
  ) async {
    if (relativePath != null && fileName != null && fileBytes != null) {
      try {
        String newRelativePath = 'uploads/saved/$fileName';
        Reference destinationReference = _storageRef.ref(newRelativePath);
        TaskSnapshot copyTask = await destinationReference.putData(fileBytes);
        if (copyTask.state == TaskState.success) {
          await deleteFile(relativePath);
          // print('파일 이동 성공');
        } else {
          // print('파일 이동 실패: 복사 중 문제 발생');
        }
        CustomToast.showToast('이미지 업로드 완료');
        return {
          'relativePath': newRelativePath,
          'fileName': fileName,
        };
      } catch (err) {
        print('업로드 오류: $err');
        CustomToast.showToast('이미지 업로드 오류');
      }
    }
    return null;
  }

  static Future<void> deleteFile(String? relativePath) async {
    // Firebase Storage 참조 얻기
    if (relativePath != null) {
      try {
        await _storageRef.ref().child(relativePath).delete();
        // print('업로드 된 파일이 성공적으로 삭제되었습니다.');
        CustomToast.showToast('Photo delete 완료');
      } catch (e, stackTrace) {
        // print('파일 삭제 중 오류 발생: $e\n$stackTrace');
        CustomToast.showToast('Photo delete 에러 $e');
      }
    } else {
      // print('deleteFile: 삭제할 파일이 없음');
    }
  }

  static Future<Map<String, dynamic>?> pdfToPng({Uint8List? fileBytes}) async {
    if (fileBytes != null) {
      final PdfDocument doc = await PdfDocument.openData(fileBytes);
      final int pages = doc.pageCount;
      List<imglib.Image> imgList = [];

      for (int i = 1; i <= pages; i++) {
        PdfPage page = await doc.getPage(i);
        PdfPageImage imgPDF = await page.render();
        Image imgOfPdf = await imgPDF.createImageDetached();
        ByteData? imgByteData =
            await imgOfPdf.toByteData(format: ImageByteFormat.png);
        if (imgByteData == null) continue;
        Uint8List imgIntBytes = imgByteData.buffer
            .asUint8List(imgByteData.offsetInBytes, imgByteData.lengthInBytes);
        imglib.Image? imgOfLib = imglib.decodeImage(imgIntBytes);
        if (imgOfLib == null) continue;
        imgList.add(imgOfLib);
      }

      // stitch images
      int totalHeight = 0;
      int totalWidth = 0;
      for (imglib.Image image in imgList) {
        totalHeight += image.height;
        totalWidth = max(totalWidth, image.width);
      }

      // 새 이미지 생성
      imglib.Image mergedImage =
          imglib.Image(width: totalWidth, height: totalHeight);
      int mergedHeight = 0;

      // 이미지를 병합
      for (imglib.Image image in imgList) {
        imglib.compositeImage(mergedImage, image,
            dstX: 0,
            dstY: mergedHeight,
            blend: imglib.BlendMode.alpha);

        mergedHeight += image.height;
      }
      Uint8List mergedBytes = imglib.encodePng(mergedImage);
      // 어플리케이션 기본 폴더
      Directory appDocumentsDirectory =
          await getApplicationDocumentsDirectory();
      String filePath = '${appDocumentsDirectory.path}/${randomString("png")}';
      File file = File(filePath);
      await file.writeAsBytes(mergedBytes);
      print('이미지가 저장되었습니다. 경로: $filePath');
      Map<String, dynamic>? result =
          await uploadFileToTmp(filePath, 'png', mergedBytes);
      if(result != null) {
         result['mergedBytes'] = mergedBytes;
         return result;
      }
    } else {
      CustomToast.showToast('파일을 선택하세요');
    }
    return null;
  }

  static Future<RecognizedText?> inputFileToText(
      {required TextRecognizer textRecognizer, String? internalPath}) async {
    if (internalPath != null) {
      try {
        InputImage inputImage = InputImage.fromFilePath(internalPath);
        RecognizedText textBlocks =
            await textRecognizer.processImage(inputImage);
        return textBlocks;
      } catch (err) {
        print(err);
      }
    }
    return null;
  }

  static Future<String?> fileToText(
      String? relativePath, String? fileName) async {
    if (relativePath != null) {
      try {
        final response = await http.post(
            Uri.parse('http://www.wooyoung-project.kro.kr/textTranslation'),
            headers: {'Content-Type': 'application/json'},
            body:
                jsonEncode({'file_url': relativePath, 'file_name': fileName}));
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

  static Future<String?> keyExtraction(String? text) async {
    // 작성 필요
    return text;
  }

  static Future<Map<String, dynamic>?> searchKmooc(String? text) async {
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
    return '${formattedDateTime}_$name.$fileExtension';
  }
}
