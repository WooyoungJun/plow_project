import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static void showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        webPosition: 'center',
        // 토스트 위치 = 중앙
        toastLength: Toast.LENGTH_SHORT,
        // 토스트 길이 짧게
        gravity: ToastGravity.TOP,
        // 위로 중력 설정
        timeInSecForIosWeb: 1,
        // 1초 유지
        webShowClose: true,
        backgroundColor: Colors.grey,
        textColor: Colors.white,
        fontSize: 16.0);
  }
}
