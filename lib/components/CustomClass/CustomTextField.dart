import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? showText;
  final bool isReadOnly;
  final int? maxLines;
  final double fontSize;
  final Icon? prefixIcon;
  final TextStyle? textStyle;
  final IconData? suffixIconData;
  final double? height;

  CustomTextField({
    this.controller,
    this.labelText,
    this.hintText,
    this.showText,
    this.isReadOnly = false,
    this.maxLines,
    this.fontSize = 16,
    this.prefixIcon,
    this.suffixIconData,
    this.textStyle,
    this.height,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late TextStyle textStyle;
  late bool isObscured;
  IconData? suffixIconData;
  final double height = 25.0;

  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.showText ?? _controller.text;
    suffixIconData = widget.suffixIconData ?? Icons.cancel;
    if (_controller.text.isEmpty) suffixIconData = null;
    isObscured = widget.labelText == "Password" ? true : false;
    textStyle = widget.textStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: widget.fontSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: TextField(
        minLines: 1,
        maxLines: widget.maxLines ?? 10,
        scrollPhysics:
            widget.maxLines == 1 ? NeverScrollableScrollPhysics() : null,
        readOnly: widget.isReadOnly,
        controller: _controller,
        obscureText: isObscured,
        style: widget.isReadOnly
            ? widget.textStyle
            : TextStyle(fontSize: widget.fontSize),
        onChanged: (text) => setState(() {
          if (text.isEmpty) {
            suffixIconData = null;
          } else {
            suffixIconData = widget.suffixIconData ?? Icons.cancel;
          }
        }),
        decoration: InputDecoration(
          hintText: widget.hintText,
          suffixIcon: widget.isReadOnly
              ? null
              : GestureDetector(
                  child: Icon(
                    suffixIconData,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  onTap: () {
                    if (suffixIconData == Icons.cancel) {
                      _controller.clear();
                    } else {
                      setState(() => isObscured = !isObscured);
                    }
                  },
                ),
          prefixIcon: widget.prefixIcon,
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
          labelText: widget.labelText,
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
