import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Logo extends StatelessWidget {
  final double height = 100.0;
  final double width = 100.0;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.pushNamed(context, '/'),
      icon: SizedBox(
        height: height,
        width: width,
        child: SvgPicture.asset(
          'assets/images/wave.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
