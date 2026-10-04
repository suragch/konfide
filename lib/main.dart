import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/topics/topic_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final storage = await StorageService.init();
  final initialPreset =
      AppThemePreset.fromString(storage.getThemePreset());
  runApp(KonfideApp(initialPreset: initialPreset));
}

class KonfideApp extends StatefulWidget {
  final AppThemePreset initialPreset;

  const KonfideApp({super.key, required this.initialPreset});

  @override
  State<KonfideApp> createState() => _KonfideAppState();
}

class _KonfideAppState extends State<KonfideApp> {
  late AppThemePreset _currentPreset;

  @override
  void initState() {
    super.initState();
    _currentPreset = widget.initialPreset;
  }

  void _onThemeChanged(AppThemePreset newPreset) {
    setState(() {
      _currentPreset = newPreset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Konfide',
      theme: AppTheme.buildTheme(_currentPreset),
      home: TopicScreen(onThemeChanged: _onThemeChanged),
    );
  }
}
