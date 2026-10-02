import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/features/cards/widgets/card_share_dialog.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final StorageService _storage = StorageService.instance;

  void _showNoteDialog(Question question) {
    final currentNote = _storage.getNote(question.id) ?? '';
    final controller = TextEditingController(text: currentNote);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
                'Personal memory or reflection:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What did someone share in response?',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _storage.saveNote(question.id, controller.text);
                await HapticService.selection();
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  Question? _resolveQuestion(String id) {
    for (final deck in _storage.getAllDecks()) {
      for (final q in deck.questions) {
        if (q.id == id) return q;
      }
    }
    return null;
  }

  String _getDeckName(String deckId) {
    final deck = _storage.getDeckById(deckId);
    return deck?.title ?? 'Deck';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteIds = _storage.getFavorites();

    final favoriteQuestions = favoriteIds
        .map((id) => _resolveQuestion(id))
        .whereType<Question>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Questions'),
      ),
      body: favoriteQuestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_outline_rounded,
                      size: 56,
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Saved Questions Yet',
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the star icon on any question to save it here alongside personal reflection notes.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: favoriteQuestions.length,
              itemBuilder: (context, index) {
                final question = favoriteQuestions[index];
                final deckTitle = _getDeckName(question.deckId);
                final note = _storage.getNote(question.id);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  deckTitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Share question',
                                  icon: const Icon(Icons.share_outlined,
                                      size: 20),
                                  onPressed: () {
                                    HapticService.light();
                                    CardShareDialog.show(
                                      context,
                                      question: question,
                                      deckTitle: deckTitle,
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Remove from saved',
                                  icon: const Icon(Icons.star_rounded,
                                      color: Color(0xFFEAB308), size: 24),
                                  onPressed: () async {
                                    await HapticService.selection();
                                    await _storage.toggleFavorite(question.id);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.text,
                          style: GoogleFonts.newsreader(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (note != null && note.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showNoteDialog(question),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          TextButton.icon(
                            onPressed: () => _showNoteDialog(question),
                            icon: const Icon(Icons.add_comment_outlined, size: 16),
                            label: const Text('Add personal note'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
