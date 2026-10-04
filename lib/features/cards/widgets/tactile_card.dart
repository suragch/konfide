import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/features/cards/widgets/card_share_dialog.dart';

class TactileCard extends StatelessWidget {
  final Question question;
  final String deckTitle;
  final Color accentColor;
  final VoidCallback? onDeleteQuestion;
  final VoidCallback? onFavoriteToggled;

  const TactileCard({
    super.key,
    required this.question,
    required this.deckTitle,
    required this.accentColor,
    this.onDeleteQuestion,
    this.onFavoriteToggled,
  });

  void _showNoteDialog(BuildContext context, StorageService storage) {
    final currentNote = storage.getNote(question.id) ?? '';
    final controller = TextEditingController(text: currentNote);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reflection Note',
            style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a personal reflection, memory, or what someone shared:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Joe shared a touching story about...',
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
                await storage.saveNote(question.id, controller.text);
                await HapticService.selection();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Question?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This question will be permanently deleted from this pack.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteQuestion?.call();
            },
            child: const Text('Delete Question'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = StorageService.instance;

    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final isFav = storage.isFavorite(question.id);
        final note = storage.getNote(question.id);

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 420,
            minHeight: 380,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                spreadRadius: 0,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Deck badge & Hide icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                deckTitle,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: accentColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete question',
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),

            const Spacer(),

            // Center: The Question Text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                question.text,
                style: GoogleFonts.newsreader(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Optional note preview if present
            if (note != null && note.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 14,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Bottom Action Bar: Favorite, Note, Share
            Container(
              padding: const EdgeInsets.only(top: 12.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Favorite Button
                  IconButton(
                    tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                    icon: Icon(
                      isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFav
                          ? const Color(0xFFEAB308)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      size: 26,
                    ),
                    onPressed: () async {
                      await HapticService.selection();
                      await storage.toggleFavorite(question.id);
                      onFavoriteToggled?.call();
                    },
                  ),

                  // Note Button
                  IconButton(
                    tooltip: 'Reflection note',
                    icon: Icon(
                      note != null && note.isNotEmpty
                          ? Icons.edit_note_rounded
                          : Icons.note_add_outlined,
                      color: note != null && note.isNotEmpty
                          ? accentColor
                          : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      size: 24,
                    ),
                    onPressed: () => _showNoteDialog(context, storage),
                  ),

                  // Share Button
                  IconButton(
                    tooltip: 'Share question',
                    icon: Icon(
                      Icons.share_outlined,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      size: 22,
                    ),
                    onPressed: () {
                      HapticService.light();
                      CardShareDialog.show(
                        context,
                        question: question,
                        deckTitle: deckTitle,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
