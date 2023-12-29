import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TextRecognitionScreen(),
    );
  }
}

class TextRecognitionScreen extends StatefulWidget {
  @override
  _TextRecognitionScreenState createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  RecognizedText _detectedTextBlocks = RecognizedText(text: '', blocks: []);

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    _pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (_pickedImage != null) {
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_pickedImage == null) return;

    InputImage inputImage = InputImage.fromFilePath(_pickedImage!.path);

    RecognizedText textBlocks = await textRecognizer.processImage(inputImage);

    setState(() {
      _detectedTextBlocks = textBlocks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Recognition'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          if (_pickedImage != null)
            Image.file(
              File(_pickedImage!.path),
              height: 200.0,
              width: 200.0,
              fit: BoxFit.cover,
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _detectedTextBlocks.blocks.length,
              itemBuilder: (context, index) {
                TextBlock textBlock = _detectedTextBlocks.blocks[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Text Block #$index'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: textBlock.lines.map((line) => Text(line.text)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
