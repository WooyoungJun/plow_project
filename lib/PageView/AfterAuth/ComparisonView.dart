import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:plow_project/components/AppBarTitle.dart';
import 'package:plow_project/components/CustomClass/CustomProgressIndicator.dart';
import 'package:provider/provider.dart';
import 'package:plow_project/components/UserProvider.dart';
import 'package:plow_project/components/CustomClass/CustomTextField.dart';

class ComparisonView extends StatefulWidget {
  @override
  State<ComparisonView> createState() => _ComparisonViewState();
}

class _ComparisonViewState extends State<ComparisonView> {
  late UserProvider userProvider;
  late String original;
  late String first;
  late String second;
  late Uint8List fileBytes;
  bool _isInitComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) async => await _initComparisonView());
  }

  Future<void> _initComparisonView() async {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    var argRef =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    fileBytes = argRef['fileBytes'] as Uint8List;
    original = argRef['original'] as String;
    first = argRef['first'] as String;
    second = argRef['second'] as String;
    setState(() => _isInitComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitComplete) return CustomProgressIndicator();
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        title: AppBarTitle(title: '모델 비교하기'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Image.memory(fileBytes, fit: BoxFit.cover),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: CustomTextField(showText: original, isReadOnly: true),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey,
            thickness: 4,
            indent: 20,
            endIndent: 20,
            height: 10,
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: CustomTextField(
                    showText: second,
                    isReadOnly: true,
                  ),
                ),
              ],
            ),
          ),
          // Expanded(
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: ListView(
          //           children: [
          //             Padding(
          //               padding: EdgeInsets.symmetric(horizontal: 8),
          //               child: CustomTextField(
          //                 showText: first,
          //                 isReadOnly: true,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       Expanded(
          //         child: ListView(
          //           children: [
          //             Padding(
          //               padding: EdgeInsets.symmetric(horizontal: 8),
          //               child: CustomTextField(
          //                 showText: second,
          //                 isReadOnly: true,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
