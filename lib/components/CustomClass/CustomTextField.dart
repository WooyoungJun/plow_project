import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller; // 부모 위젯에서 활용할 텍스트 컨트롤러
  final String? labelText;
  final String? hintText; // 텍스트 필드에 노출할 텍스트
  final IconData? iconData; // 텍스트 폼에 적용할 아이콘
  final double? iconSize;
  final bool isReadOnly;
  final int? maxLines;
  final double fontSize;
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
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  final double height = 25.0;

  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(6));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: TextField(
        minLines: 1,
        maxLines: widget.maxLines,
        readOnly: widget.isReadOnly,
        controller: widget.controller,
        obscureText: widget.labelText == "Password" ? true : false,
        style: widget.isReadOnly
            ? widget.textStyle
            : TextStyle(fontSize: widget.fontSize),
        onChanged: (text) => setState(() {}),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          prefixIcon: widget.icon,
          labelText: widget.labelText,
          hintText: widget.hintText,
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
