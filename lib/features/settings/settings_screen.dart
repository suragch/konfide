import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<AppThemePreset> onThemeChanged;

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPresetName = _storage.getThemePreset();
    final currentPreset = AppThemePreset.fromString(currentPresetName);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Atmosphere & Theme Section
          Text(
            'Atmosphere & Palette',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the ambient mood that fits your conversation setting.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),

          ...AppThemePreset.values.map((preset) {
            final isSelected = preset == currentPreset;
            final palette = AppPalette.forPreset(preset);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.15),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: palette.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border, width: 1.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  preset.displayName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : null,
                onTap: () async {
                  await HapticService.selection();
                  await _storage.setThemePreset(preset.name);
                  widget.onThemeChanged(preset);
                  setState(() {});
                },
              ),
            );
          }),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // About Section
          Text(
            'About Konfide',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Konfide',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'v1.1.0',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Konfide is deliberately designed to be the antidote to screen addiction. No endless feeds, no ads, no algorithms, and 100% offline.\n\nIts sole purpose is to spark genuine, heartwarming, eye-to-eye conversations with the people right beside you.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
