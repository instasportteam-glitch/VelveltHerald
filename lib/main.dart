import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'velvet_webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const VelvetHeraldApp());
}

class VelvetHeraldApp extends StatelessWidget {
  const VelvetHeraldApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Velvet Herald',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1B0D14),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE9C37A),
        surface: Color(0xFF1B0D14),
      ),
    ),
    home: const VelvetWebView(),
  );
}
