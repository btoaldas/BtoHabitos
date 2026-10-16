import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.auth});
  final AuthController auth;
  @override
  Widget build(BuildContext context) => AuthForm(auth: auth, register: true);
}
