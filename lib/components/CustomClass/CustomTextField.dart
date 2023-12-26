import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String? labelText;
  final String? hintText; // 텍스트 필드에 노출할 텍스트
  final IconData? icon; // 텍스트 폼에 적용할 아이콘
  final double? iconSize;
  final bool isReadOnly;
  final int? maxLines;
  final double? height;
  late Icon? iconData;
  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(10));
  late TextStyle textStyle;
  double? fontSize;

  CustomTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.icon,
    this.iconSize,
    this.isReadOnly = false,
    this.maxLines,
    this.height = 25.0,
    this.fontSize = 12.5,
    this.iconData,
  }) {
    textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
      fontSize: fontSize,
    );
    iconData = iconData ?? (icon != null ? Icon(icon, size: iconSize) : null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        maxLines: maxLines,
        readOnly: isReadOnly,
        controller: controller,
        obscureText: labelText == "Password" ? true : false,
        style: isReadOnly ? textStyle : TextStyle(color:Colors.grey, fontSize: fontSize),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          prefixIcon: iconData,
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
