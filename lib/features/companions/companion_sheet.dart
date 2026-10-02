import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';

class CompanionSheet extends StatefulWidget {
  const CompanionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CompanionSheet(),
    );
  }

  @override
  State<CompanionSheet> createState() => _CompanionSheetState();
}

class _CompanionSheetState extends State<CompanionSheet> {
  final StorageService _storage = StorageService.instance;

  void _showAddCompanionDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Companion',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who are you having conversations with? Their progress and seen cards will be saved separately.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g., Joe, Mary, Dad, Sarah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newCompanion = Companion(
                  id: const Uuid().v4(),
                  name: name,
                  createdAt: DateTime.now(),
                  colorIndex: (_storage.getCompanions().length) % 6,
                );
                await _storage.addCompanion(newCompanion);
                await _storage.setActiveCompanionId(newCompanion.id);
                await HapticService.selection();
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss dialog
                  setState(() {});
                }
              }
            },
            child: const Text('Add Person'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompanion(Companion companion) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove ${companion.name}?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove ${companion.name} and their conversation history. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _storage.deleteCompanion(companion.id);
              await HapticService.medium();
              if (context.mounted) {
                Navigator.of(context).pop();
                setState(() {});
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getCompanionColor(int index) {
    const colors = [
      Color(0xFFD97736),
      Color(0xFF2563EB),
      Color(0xFF16A34A),
      Color(0xFFE11D48),
      Color(0xFF8B5CF6),
      Color(0xFF0D9488),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companions = _storage.getCompanions();
    final activeId = _storage.getActiveCompanionId();

    return SafeArea(
      top: false,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Add button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Conversations With...',
                            style: GoogleFonts.newsreader(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select who you are talking with to save progress',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: _showAddCompanionDialog,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add Person'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Companion List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: companions.length,
                itemBuilder: (context, index) {
                  final companion = companions[index];
                  final isSelected = companion.id == activeId;
                  final color = _getCompanionColor(companion.colorIndex);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        companion.initials,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      companion.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      companion.isDefault
                          ? 'Default general profile'
                          : 'Custom companion profile',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!companion.isDefault)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            tooltip: 'Remove companion',
                            onPressed: () => _confirmDeleteCompanion(companion),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await HapticService.selection();
                      await _storage.setActiveCompanionId(companion.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
