import 'package:flutter/material.dart';

class AppBarTitle {
  final String title;
  AppBarTitle({required this.title});
  Widget get widget => Text(
    title,
    style: TextStyle(
      color: Colors.white,
      fontSize: 20,
    ),
  );
}