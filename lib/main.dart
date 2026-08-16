import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XynovaApp());
}

class XynovaApp extends StatelessWidget {
  const XynovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xynova',
      debugShowCheckedModeBanner: false,
      theme: XynovaTheme.light(),
      darkTheme: XynovaTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
