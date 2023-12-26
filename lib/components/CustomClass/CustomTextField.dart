import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String? labelText;
  final String? hintText; // 텍스트 필드에 노출할 텍스트
  final IconData? iconData; // 텍스트 폼에 적용할 아이콘
  final double? iconSize;
  final bool isReadOnly;
  final int? maxLines;
  final double? height;
  final double? fontSize;
  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(6));
  final Icon? icon;
  final TextStyle? textStyle;

  CustomTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.iconData,
    this.iconSize = 15.0,
    this.isReadOnly = false,
    this.maxLines,
    this.height = 25.0,
    this.fontSize = 12.5,
    Icon? icon,
    TextStyle? textStyle,
  })  : icon =
            icon ?? (iconData != null ? Icon(iconData, size: iconSize) : null),
        textStyle = textStyle ??
            TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: fontSize,
            );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        maxLines: maxLines,
        readOnly: isReadOnly,
        controller: controller,
        obscureText: labelText == "Password" ? true : false,
        style: isReadOnly ? textStyle : TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          prefixIcon: icon,
          labelText: labelText,
          hintText: hintText,
          fillColor: Colors.white,
          filled: true,
          border: defaultDesign,
          enabledBorder: defaultDesign,
          focusedBorder: defaultDesign,
          errorBorder: defaultDesign,
          focusedErrorBorder: defaultDesign,
        ),
      ),
    );
  }
}
