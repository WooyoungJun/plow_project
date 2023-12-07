// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';

import '../size.dart';

// 입력 form 위젯
class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Icon icon;

  const CustomTextFormField(
      {super.key, required this.controller, required this.labelText, required this.icon});

  @override
  State<CustomTextFormField> createState() =>
      _CustomTextFormFieldState(controller, labelText, icon);
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final String labelText;
  final Icon icon;
  final TextEditingController _controller;

  _CustomTextFormFieldState(this._controller, this.labelText, this.icon);

  @override
  Widget build(BuildContext context) {
    final defaultDesign =
        OutlineInputBorder(borderRadius: BorderRadius.circular(20));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: smallGap),
        TextField(
          controller: _controller,
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
            // hintText: "$labelText을 입력하세요",
            // 기본 디자인
            enabledBorder: defaultDesign,
            // 클릭 시 디자인
            focusedBorder: defaultDesign,
            // 에러 발생 시 디자인
            errorBorder: defaultDesign,
            // 에러 발생 후 클릭 시 디자인
            focusedErrorBorder: defaultDesign,
          ),
        ),
      ],
    );
  }
}
