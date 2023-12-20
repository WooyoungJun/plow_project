import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String? labelText;
  final String? hintText; // 텍스트 필드에 노출할 텍스트
  final Icon? icon; // 텍스트 폼에 적용할 아이콘
  final bool isReadOnly;
  final int? maxLines;
  static const TextStyle textStyle =
      TextStyle(fontWeight: FontWeight.bold, color: Colors.grey);

  CustomTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.icon,
    this.isReadOnly = false,
    this.maxLines,
  });

  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(20));

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: maxLines,
      readOnly: isReadOnly,
      controller: controller,
      // 비밀번호면 *로 표시
      obscureText: labelText == "Password" ? true : false,
      style: isReadOnly ? textStyle : null,
      // isReadOnly가 false이면 기본 스타일 사용
      decoration: InputDecoration(
        prefixIcon: icon,
        // form icon
        labelText: labelText,
        // form text
        hintText: hintText,
        hintStyle: textStyle,
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
}
