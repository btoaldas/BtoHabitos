import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => AuthForm(auth: auth, register: false);
}
