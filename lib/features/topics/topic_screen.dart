import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/deck_exchange_service.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/core/theme/app_theme.dart';
import 'package:konfide/features/cards/widgets/card_share_dialog.dart';
import 'package:konfide/features/companions/companion_sheet.dart';
import 'package:konfide/features/custom_decks/custom_deck_screen.dart';
import 'package:konfide/features/custom_decks/import_deck_sheet.dart';
import 'package:konfide/features/favorites/favorites_screen.dart';
import 'package:konfide/features/questions/question_screen.dart';
import 'package:konfide/features/settings/settings_screen.dart';

class TopicScreen extends StatefulWidget {
  final ValueChanged<AppThemePreset> onThemeChanged;

  const TopicScreen({super.key, required this.onThemeChanged});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final StorageService _storage = StorageService.instance;
  late Question _dailySpark;

  @override
  void initState() {
    super.initState();
    _pickDailySpark();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  void _pickDailySpark() {
    final now = DateTime.now();
    final dayOfYear = now.year * 365 + now.month * 31 + now.day;
    final allQuestions = _storage.getAllDecks().expand((d) => d.questions).toList();
    if (allQuestions.isNotEmpty) {
      _dailySpark = allQuestions[dayOfYear % allQuestions.length];
    } else {
      _dailySpark = const Question(
        id: 'spark_default',
        text: 'What is something simple in your life right now that you feel deeply grateful for?',
        deckId: 'getting_to_know_you',
      );
    }
  }

  void _confirmDeleteDeck(QuestionDeck deck) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete "${deck.title}"?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'This will permanently delete this pack and its questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final deleteFuture = _storage.deleteDeck(deck.id);
              await HapticService.medium();
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${deck.title}" pack'),
                    duration: const Duration(seconds: 3),
                    persist: false,
                    behavior: SnackBarBehavior.floating,
                    showCloseIcon: true,
                  ),
                );
              }
              await deleteFuture;
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resetDeckProgress(QuestionDeck deck, Companion companion) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Progress?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Reset questions in "${deck.title}" with ${companion.name} back to the beginning?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _storage.resetProgress(companion.id, deck.id);
              await HapticService.selection();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCompanion = _storage.getActiveCompanion();
    final presetDecks = _storage.getPresetDecks();
    final visibleCurated = presetDecks;

    final customDecks = _storage.getCustomDecks();
    final favoritesCount = _storage.getFavorites().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Konfide',
          style: GoogleFonts.newsreader(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Menu',
            onSelected: (value) {
              HapticService.light();
              switch (value) {
                case 'favorites':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
                  );
                  break;
                case 'import':
                  ImportDeckSheet.show(context);
                  break;
                case 'create':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CustomDeckScreen()),
                  );
                  break;
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'favorites',
                child: Row(
                  children: [
                    const Icon(Icons.star_outline_rounded, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Saved Questions')),
                    if (favoritesCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAB308),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$favoritesCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Create Pack'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Import Pack'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Daily Spark Card
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.14),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'DAILY SPARK',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _storage.isFavorite(_dailySpark.id)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: _storage.isFavorite(_dailySpark.id)
                                ? const Color(0xFFEAB308)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: _storage.isFavorite(_dailySpark.id)
                              ? 'Remove from saved'
                              : 'Save question',
                          onPressed: () async {
                            await HapticService.selection();
                            await _storage.toggleFavorite(_dailySpark.id);
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Share daily spark',
                          onPressed: () {
                            HapticService.light();
                            CardShareDialog.show(
                              context,
                              question: _dailySpark,
                              deckTitle: 'Daily Spark',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _dailySpark.text,
                  style: GoogleFonts.newsreader(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Header for Decks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Conversation Packs',
                    style: GoogleFonts.newsreader(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticService.light();
                    CompanionSheet.show(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'for ${activeCompanion.name}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Curated Decks List
          if (visibleCurated.isEmpty)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No standard packs available.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...visibleCurated.map((deck) {
            final progress =
                _storage.getProgress(activeCompanion.id, deck.id);
            final seenCount = progress.seenQuestionIds
                .where((id) => deck.questions.any((q) => q.id == id))
                .length;
            final totalCount = deck.questions.length;
            final progressFraction = totalCount > 0 ? (seenCount / totalCount) : 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticService.light();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => QuestionScreen(deck: deck),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: deck.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(deck.icon, color: deck.accentColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        deck.title,
                                        style: GoogleFonts.newsreader(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz_rounded,
                                          size: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      onSelected: (val) async {
                                        if (val == 'customize') {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => CustomDeckScreen(initialDeck: deck),
                                            ),
                                          );
                                        } else if (val == 'export') {
                                          await DeckExchangeService.shareDeckFile(context, deck);
                                        } else if (val == 'reset') {
                                          _resetDeckProgress(
                                              deck, activeCompanion);
                                        } else if (val == 'delete') {
                                          _confirmDeleteDeck(deck);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'customize',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Customize',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'export',
                                          child: Row(
                                            children: [
                                              Icon(Icons.share_outlined, size: 18),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Export Pack (.json)',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'reset',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.refresh_rounded, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Reset progress for ${activeCompanion.name}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded,
                                                  size: 18, color: Colors.redAccent),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Delete Pack',
                                                  style: TextStyle(
                                                      color: Colors.redAccent),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  deck.description,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress bar & Card count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  seenCount == 0
                                      ? '$totalCount questions'
                                      : '$seenCount of $totalCount explored with ${activeCompanion.name}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (seenCount > 0 && seenCount >= totalCount) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Completed ✓',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              backgroundColor:
                                  deck.accentColor.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  deck.accentColor),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Custom Decks Section
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Custom Packs',
                  style: GoogleFonts.newsreader(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    HapticService.light();
                    ImportDeckSheet.show(context);
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Import Pack'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (customDecks.isEmpty)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create or Import Packs',
                            style: GoogleFonts.newsreader(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personalize your conversations by creating your own pack or importing one from a friend.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: () {
                        HapticService.light();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CustomDeckScreen(),
                          ),
                        );
                      },
                      child: const Text('New Pack'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...customDecks.map((deck) {
              final progress =
                  _storage.getProgress(activeCompanion.id, deck.id);
              final totalCount = deck.questions.length;
              final seenCount = progress.seenQuestionIds
                  .where((id) => deck.questions.any((q) => q.id == id))
                  .length;
              final progressFraction =
                  totalCount > 0 ? (seenCount / totalCount) : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticService.light();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => QuestionScreen(deck: deck),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: deck.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(deck.icon,
                                  color: deck.accentColor, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          deck.title,
                                          style: GoogleFonts.newsreader(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                            Icons.more_horiz_rounded,
                                            size: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        onSelected: (val) async {
                                          if (val == 'edit') {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    CustomDeckScreen(
                                                        initialDeck: deck),
                                              ),
                                            );
                                          } else if (val == 'duplicate') {
                                            final copy = await _storage.duplicateDeck(deck);
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) => CustomDeckScreen(initialDeck: copy),
                                                ),
                                              );
                                            }
                                          } else if (val == 'export') {
                                            await DeckExchangeService.shareDeckFile(context, deck);
                                          } else if (val == 'reset') {
                                            _resetDeckProgress(deck, activeCompanion);
                                          } else if (val == 'delete') {
                                            _confirmDeleteDeck(deck);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit_outlined, size: 18),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Edit Pack',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'duplicate',
                                            child: Row(
                                              children: [
                                                Icon(Icons.copy_rounded, size: 18),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Duplicate Pack',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'export',
                                            child: Row(
                                              children: [
                                                Icon(Icons.share_outlined, size: 18),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Export Pack (.json)',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'reset',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.refresh_rounded, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Reset progress for ${activeCompanion.name}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Delete Pack',
                                                    style: TextStyle(color: Colors.redAccent),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    deck.description,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    seenCount == 0
                                        ? '$totalCount questions'
                                        : '$seenCount of $totalCount explored with ${activeCompanion.name}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (seenCount > 0 && seenCount >= totalCount) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Completed ✓',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressFraction,
                                backgroundColor:
                                    deck.accentColor.withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    deck.accentColor),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
