import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/main_screen.dart';

class RollClickerApp extends StatelessWidget {
  const RollClickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '롤러코스터 키우기',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainScreen(),
    );
  }
}
