import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
    PackageInfo.setMockInitialValues(
      appName: 'Konfide',
      packageName: 'dev.suragch.konfide',
      version: '2.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  testWidgets('SettingsScreen displays real app version from platform', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('v2.0.0'), findsOneWidget);
  });
}
