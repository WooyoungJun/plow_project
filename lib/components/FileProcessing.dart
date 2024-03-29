import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http; // flask 통신
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as imglib;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:plow_project/components/CustomClass/CustomToast.dart';
import 'package:external_path/external_path.dart';

class FileProcessing {
  static final FirebaseStorage _storageRef = FirebaseStorage.instance;
  static final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static String externalDirectory = '';

  //다운로드 폴더 경로 받아오기
  static Future<void> getPublicDownloadFolderPath() async {
    late String downloadDirPath;
    // 만약 다운로드 폴더가 존재하지 않는다면 앱내 파일 패스를 대신 return
    if (Platform.isAndroid) {
      downloadDirPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);
      Directory dir = Directory(downloadDirPath);

      if (!dir.existsSync()) {
        downloadDirPath = (await getExternalStorageDirectory())!.path;
      }
    } else if (Platform.isIOS) {
      downloadDirPath = (await getApplicationDocumentsDirectory()).path;
    }
    externalDirectory = downloadDirPath;
    print(externalDirectory);
  }

  static Future<Uint8List?> loadFileFromStorage({String? relativePath}) async {
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
            internalPath: fileResult.files.first.path!,
            fileExtension: fileExtension,
            fileBytes: fileBytes);
      } else {
        CustomToast.showToast('파일을 선택해주세요');
      }
    } catch (err) {
      CustomToast.showToast('파일 선택 오류: $err');
      print('파일 선택 오류: $err');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getImage(
      {required ImagePicker picker}) async {
    try {
      XFile? imageFile = await picker.pickImage(source: ImageSource.camera);

      if (imageFile != null) {
        String fileExtension = imageFile.path.split('.').last.toLowerCase();
        if (allowedExtensions.contains(fileExtension)) {
          Uint8List fileBytes = await imageFile.readAsBytes();
          return await uploadFileToTmp(
              internalPath: imageFile.path,
              fileExtension: fileExtension,
              fileBytes: fileBytes);
        } else {
          CustomToast.showToast('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print('선택된 파일은 jpg, jpeg, png 파일이 아닙니다.');
          print(fileExtension);
        }
      } else {
        CustomToast.showToast('파일을 선택해주세요');
      }
    } catch (err) {
      CustomToast.showToast('이미지 선택 오류: $err');
      print('이미지 선택 오류: $err');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadFileToTmp(
      {required String internalPath,
      required String fileExtension,
      required Uint8List fileBytes}) async {
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
      CustomToast.showToast('이미지 업로드 오류: $err');
      print('이미지 업로드 오류: $err');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> transitionToStorage({
    String? relativePath,
    String? fileName,
    Uint8List? fileBytes,
  }) async {
    if (relativePath != null && fileName != null && fileBytes != null) {
      try {
        String newRelativePath = 'uploads/saved/$fileName';
        if (newRelativePath == relativePath) return null;
        Reference destinationReference = _storageRef.ref(newRelativePath);
        TaskSnapshot copyTask = await destinationReference.putData(fileBytes);
        if (copyTask.state == TaskState.success) {
          await deleteFile(relativePath: relativePath);
          CustomToast.showToast('이미지 업로드 완료');
          return {
            'relativePath': newRelativePath,
            'fileName': fileName,
          };
        } else {
          CustomToast.showToast('파일 이동 실패: 복사 중 문제 발생');
        }
      } catch (err) {
        CustomToast.showToast('이미지 업로드 오류');
        print('업로드 오류: $err');
      }
    }
    return null;
  }

  static Future<void> deleteFile({String? relativePath}) async {
    if (relativePath != null) {
      try {
        await _storageRef.ref().child(relativePath).delete();
        CustomToast.showToast('Photo delete 완료');
      } catch (e, stackTrace) {
        CustomToast.showToast('Photo delete 에러 $e');
        print('파일 삭제 중 오류 발생: $e\n$stackTrace');
      }
    }
  }

  static Future<Map<String, dynamic>?> pdfToPng({
    required Uint8List fileBytes,
  }) async {
    try {
      PdfDocument doc = await PdfDocument.openData(fileBytes);
      int pages = doc.pageCount;
      List<imglib.Image> imgList = [];

      for (int i = 1; i <= pages; i++) {
        PdfPage page = await doc.getPage(i);
        PdfPageImage imgPDF = await page.render();
        Image imgOfPdf = await imgPDF.createImageDetached();
        ByteData? imgByteData =
            await imgOfPdf.toByteData(format: ImageByteFormat.png);
        // png byte data로 변환
        if (imgByteData == null) continue;
        Uint8List imgIntBytes = imgByteData.buffer
            .asUint8List(imgByteData.offsetInBytes, imgByteData.lengthInBytes);
        imglib.Image? imgOfLib = imglib.decodeImage(imgIntBytes);
        // Uint8List로 변환 후 image로 변환
        if (imgOfLib == null) continue;
        imgList.add(imgOfLib);
      }

      int totalHeight = 0;
      int totalWidth = 0;
      // 새 이미지의 height, width 설정
      for (imglib.Image image in imgList) {
        totalHeight += image.height;
        totalWidth = max(totalWidth, image.width);
      }

      imglib.Image mergedImage =
          imglib.Image(width: totalWidth, height: totalHeight);
      // 새 이미지 생성

      int mergedHeight = 0;
      for (imglib.Image image in imgList) {
        // 이미지를 병합
        imglib.compositeImage(mergedImage, image,
            dstX: 0, dstY: mergedHeight, blend: imglib.BlendMode.alpha);
        mergedHeight += image.height;
      }
      Uint8List mergedBytes = imglib.encodePng(mergedImage);

      String filePath = '$externalDirectory/${randomString("png")}';
      File file = File(filePath);
      await file.writeAsBytes(mergedBytes);
      print('이미지가 저장되었습니다. 경로: $filePath');
      // 어플리케이션 기본 폴더에 저장

      Map<String, dynamic>? result = await uploadFileToTmp(
          internalPath: filePath, fileExtension: 'png', fileBytes: mergedBytes);

      if (result != null) {
        result['mergedBytes'] = mergedBytes;
        return result;
      }
    } catch (err) {
      CustomToast.showToast('pdf to png 오류: $err');
      print('pdf to png 오류: $err');
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

  static Future<String?> storageFileToText(
      {required String relativePath, required String fileName}) async {
    try {
      var response = await http.post(
        Uri.parse('http://www.wooyoung-project.kro.kr:4752/textTranslation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_url': relativePath}),
      );

      if (response.statusCode == 200) {
        CustomToast.showToast('텍스트 추출 성공');
        print('텍스트 추출 성공: ${response.body}');
        return response.body;
      } else {
        print('텍스트 추출 연결 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('텍스트 추출 연결 오류: $e');
    }
    return null;
  }

  // keybert이용하여 keyword 추출하기
  static Future<String?> keyExtraction({required String extractedText}) async {
    try {
      var response = await http.post(
        Uri.parse('http://www.wooyoung-project.kro.kr:4752/extract-keywords'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'text': extractedText}),
      );

      if (response.statusCode == 200) {
        CustomToast.showToast('키워드 추출 연결 성공');
        String result = utf8.decode(response.bodyBytes);
        List<dynamic> result2 = json.decode(result);
        String finalResult = result2.take(3).map((item) => '${item[0]}').join(' ');
        print('키워드 추출 연결 성공 : $finalResult');
        return finalResult;
      } else {
        print('키워드 추출 연결 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('키워드 추출 연결 오류: $e');
    }
    return null;
  }

  // keybert이용하여 keyword 추출하기
  static Future<String?> searchCourse({required String keyword}) async {
    try {
      var response = await http.post(
        Uri.parse('http://www.wooyoung-project.kro.kr:4752/search'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'keyword': keyword}),
      );
      print('${response.statusCode}');

      if (response.statusCode == 200) {
        CustomToast.showToast('강의 검색 성공');
        String result = utf8.decode(response.bodyBytes);
        List<dynamic> result2 = json.decode(result);
        print('강의 검색 성공: $result2');
        return result2[0]['course_url'] as String;
      } else {
        print('강의 검색 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('강의 검색 연결 오류: $e');
    }
    return null;
  }

  // summary 부분 : trained KoBART
  static Future<String?> makeSummary(
      {required String text, required String keywords}) async {
    try {
      var response = await http.post(
        Uri.parse('http://www.wooyoung-project.kro.kr:4752/generate-summary'),
        headers: {'Content-Type': 'application/json'},
        // flask에 현재 text만 받아 요약하도록 만들었습니다.
        // keyword는 가중치를 더해 요약문을 만드는 로직이 연결이 안되어 수정하고
        // keyword에 대한 로직을 flask서버에 추가해야합니다.(~0102 24:00)
        body: jsonEncode({'text': text, 'keywords': keywords}),
      );

      if (response.statusCode == 200) {
        CustomToast.showToast('Summary 연결 성공');
        String result = utf8.decode(response.bodyBytes);
        String result2 = json.decode(result);
        print('Summary 연결 성공: $result2');
        return result2;
      } else {
        CustomToast.showToast('Summary 연결 실패 ${response.statusCode}');
        print('Summary 연결 실패: ${response.statusCode}');
      }
    } catch (e) {
      CustomToast.showToast('Summary 연결 오류 $e');
      print('Summary 연결 오류: $e');
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
    return '${formattedDateTime}_$name.$fileExtension';
  }
}
