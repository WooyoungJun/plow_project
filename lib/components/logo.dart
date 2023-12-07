import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: SvgPicture.asset(
            'assets/images/wave.svg',
            fit: BoxFit.contain,
          ),
        ), // 로고 이미지
      ],
    );
  }
}
