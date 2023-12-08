// ignore_for_file: no_logic_in_create_state

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:plow_project/components/user_provider.dart';

import '../size.dart';
import 'custom_text_form_field.dart';

class CustomForm extends StatefulWidget {
  final UserProvider userProvider;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String buttonText;
  final String route;

  CustomForm({
    super.key,
    required this.userProvider,
    required this.emailController,
    required this.passwordController,
    required this.buttonText,
    required this.route,
  });

  @override
  State<CustomForm> createState() => _CustomFormState(
        userProvider: userProvider,
        emailController: emailController,
        passwordController: passwordController,
        buttonText: buttonText,
        route: route,
      );
}

class _CustomFormState extends State<CustomForm> {
  final UserProvider userProvider;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String buttonText;
  final String route;
  String msg = '';

  _CustomFormState({
    required this.userProvider,
    required this.emailController,
    required this.passwordController,
    required this.buttonText,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          controller: emailController,
          labelText: 'Email',
          icon: Icon(Icons.email),
        ),
        const SizedBox(height: mediumGap),
        CustomTextFormField(
          controller: passwordController,
          labelText: 'Password',
          icon: Icon(Icons.lock),
        ),
        const SizedBox(height: largeGap),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              )),
          onPressed: () async {
            late String result;
            if (buttonText == 'login') {
              result = await userProvider.signIn(
                  emailController.text, passwordController.text);
            } else if (buttonText == 'signUp') {
              result = await userProvider.signUp(
                  emailController.text, passwordController.text);
            }

            // 위젯이 마운트되지 않으면 context에 아무것도 없을 수 있음
            if (!mounted) return;

            if (result == '성공') {
              print('$buttonText 성공');
              Fluttertoast.showToast(
                  msg: '$buttonText 성공!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
                  timeInSecForIosWeb: 5,
                  backgroundColor: Colors.grey,
                  textColor: Colors.white,
                  fontSize: 16.0);
              Navigator.pushReplacementNamed(context, route);
            } else {
              setState(() => msg = result);
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ),
        ),
        SizedBox(
          width: 400,
          child: Text(
            msg,
            style: TextStyle(
              fontSize: 14,
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
