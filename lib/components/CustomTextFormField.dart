// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';

import 'Size.dart';

// 입력 form 위젯
class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String labelText; // 텍스트 폼에 표현할 텍스트(login/password)
  final Icon icon; // 텍스트 폼에 적용할 아이콘

  const CustomTextFormField({required this.controller, required this.labelText, required this.icon});

  @override
  State<CustomTextFormField> createState() =>
      _CustomTextFormFieldState(controller, labelText, icon);
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final TextEditingController _controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String _labelText; // 텍스트 폼에 표현할 텍스트(login/password)
  final Icon _icon; // 텍스트 폼에 적용할 아이콘

  _CustomTextFormFieldState(this._controller, this._labelText, this._icon);

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
          obscureText: _labelText == "Password" ? true : false,
          decoration: InputDecoration(
            prefixIcon: _icon,
            // form icon
            labelText: _labelText,
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
        ),
      ],
    );
  }
}
