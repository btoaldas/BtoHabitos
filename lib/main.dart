import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bindings/app_binding.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/estado_operacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final binding = AppBinding();
  unawaited(binding.auth.restore());
  runApp(BtoHabitosApp(binding: binding));
}

class BtoHabitosApp extends StatelessWidget {
  const BtoHabitosApp({super.key, required this.binding});
  final AppBinding binding;

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BtoHábitos',
    theme: appTheme(),
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Obx(() {
      final auth = binding.auth;
      if (auth.restoring.value) {
        return const Scaffold(
          body: EstadoOperacion(loading: true, title: 'Recuperando su sesión…'),
        );
      }
      if (auth.restoreError.value != null) {
        return Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EstadoOperacion(
                title: 'No pudimos comprobar su sesión',
                message: auth.restoreError.value,
                onRetry: auth.restore,
                icon: Icons.cloud_off_outlined,
              ),
              TextButton(
                onPressed: auth.logout,
                child: const Text('Cerrar sesión y volver al acceso'),
              ),
            ],
          ),
        );
      }
      final identity = binding.sessions.current.value;
      if (identity == null) {
        return auth.registerMode.value
            ? RegisterScreen(auth: auth)
            : LoginScreen(auth: auth);
      }
      // Las rutas y diálogos privados viven bajo esta sesión y se descartan juntos.
      return Navigator(
        key: ValueKey(identity),
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => HomeScreen(binding: binding, identity: identity),
        ),
      );
    }),
  );
}
