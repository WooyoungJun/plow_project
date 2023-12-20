import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3.0, // 선 두께 설정
        valueColor: AlwaysStoppedAnimation(Colors.blue), // 색상 설정
      ),
    );
  }
}
