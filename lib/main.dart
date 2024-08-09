import 'package:flutter/material.dart';
import 'package:konfide/features/topics/topic_screen.dart';

void main() {
  runApp(const KonfideApp());
}

class KonfideApp extends StatelessWidget {
  const KonfideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Konfide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      themeMode: ThemeMode.system,
      home: const TopicScreen(),
    );
  }
}
