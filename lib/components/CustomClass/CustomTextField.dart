import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? showText;
  final bool isReadOnly;
  final int? maxLines;
  final double fontSize;
  final Icon? icon;
  final TextStyle? textStyle;

  CustomTextField({
    this.controller,
    this.labelText,
    this.showText,
    this.isReadOnly = false,
    this.maxLines,
    this.fontSize = 16,
    this.icon,
    this.textStyle,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  late TextStyle textStyle;
  final double height = 25.0;

  final defaultDesign =
      OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.text = widget.showText ?? '';
    textStyle = widget.textStyle ??
        TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: widget.fontSize,
        );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      minLines: 1,
      maxLines: widget.maxLines,
      readOnly: widget.isReadOnly,
      controller: _controller,
      obscureText: widget.labelText == "Password" ? true : false,
      style: widget.isReadOnly
          ? widget.textStyle
          : TextStyle(fontSize: widget.fontSize),
      onChanged: (text) => setState(() {}),
      decoration: InputDecoration(
        suffixIcon: widget.isReadOnly
            ? null
            : GestureDetector(
                child: Icon(Icons.cancel, color: Colors.blueAccent, size: 20),
                onTap: () => _controller.clear(),
              ),
        prefixIcon: widget.icon,
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
    );
  }
}
