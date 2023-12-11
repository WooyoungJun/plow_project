import 'package:flutter/material.dart';

class CustomTextField {
  final TextEditingController controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String? labelText;
  final String? hintText; // 텍스트 필드에 노출할 텍스트
  final Icon? icon; // 텍스트 폼에 적용할 아이콘
  CustomTextField({required this.controller, this.labelText, this.hintText, this.icon});

  final defaultDesign =
  OutlineInputBorder(borderRadius: BorderRadius.circular(20));

  get widget => TextField(
    controller: controller,
    // 비밀번호면 *로 표시
    obscureText: labelText == "Password" ? true : false,
    decoration: InputDecoration(
      prefixIcon: icon,
      // form icon
      labelText: labelText,
      // form text
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      // 기본 디자인
      enabledBorder: defaultDesign,
      // 클릭 시 디자인
      focusedBorder: defaultDesign,
      // 에러 발생 시 디자인
      errorBorder: defaultDesign,
      // 에러 발생 후 클릭 시 디자인
      focusedErrorBorder: defaultDesign,
    ),
  );
}

