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

  void _restoreHiddenQuestions() async {
    await _storage.unhideAllQuestions();
    await HapticService.selection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All hidden questions restored')),
      );
      setState(() {});
    }
  }

  void _restoreHiddenDecks() async {
    final hidden = _storage.getHiddenDeckIds().toList();
    for (final id in hidden) {
      await _storage.unhideDeck(id);
    }
    await HapticService.selection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All hidden packs restored')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPresetName = _storage.getThemePreset();
    final currentPreset = AppThemePreset.fromString(currentPresetName);
    final hiddenQuestionsCount = _storage.getHiddenQuestionIds().length;
    final hiddenDecksCount = _storage.getHiddenDeckIds().length;

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

          // Content Management Section
          Text(
            'Hidden & Deleted Content',
            style: GoogleFonts.newsreader(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage questions and packs you chose to hide from your decks.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),

          Card(
            child: ListTile(
              title: const Text('Hidden Questions'),
              subtitle: Text(
                hiddenQuestionsCount == 0
                    ? 'No questions are hidden'
                    : '$hiddenQuestionsCount question${hiddenQuestionsCount == 1 ? '' : 's'} hidden',
              ),
              trailing: hiddenQuestionsCount > 0
                  ? TextButton(
                      onPressed: _restoreHiddenQuestions,
                      child: const Text('Restore All'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Hidden Packs'),
              subtitle: Text(
                hiddenDecksCount == 0
                    ? 'No packs are hidden'
                    : '$hiddenDecksCount pack${hiddenDecksCount == 1 ? '' : 's'} hidden',
              ),
              trailing: hiddenDecksCount > 0
                  ? TextButton(
                      onPressed: _restoreHiddenDecks,
                      child: const Text('Restore All'),
                    )
                  : null,
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Restore Standard Packs'),
              subtitle: const Text(
                'Restore standard question packs if modified or missing.',
              ),
              trailing: TextButton(
                onPressed: () async {
                  await _storage.restorePresetDecks();
                  await HapticService.selection();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Standard question packs restored'),
                      ),
                    );
                  }
                },
                child: const Text('Restore'),
              ),
            ),
          ),

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
