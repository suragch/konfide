import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/companion.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/deck_exchange_service.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';
import 'package:konfide/features/cards/widgets/tactile_card_stack.dart';
import 'package:konfide/features/companions/companion_sheet.dart';

class QuestionScreen extends StatefulWidget {
  final QuestionDeck deck;

  const QuestionScreen({
    super.key,
    required this.deck,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final StorageService _storage = StorageService.instance;
  late Companion _activeCompanion;
  late List<Question> _questions;
  int _currentIndex = 0;
  int _resetVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadDeckData();
    _storage.addListener(_onStorageUpdate);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) {
      setState(() {
        _resetVersion++;
        _loadDeckData();
      });
    }
  }

  void _loadDeckData() {
    _activeCompanion = _storage.getActiveCompanion();
    final hiddenQuestionIds = _storage.getHiddenQuestionIds();

    _questions = widget.deck.visibleQuestions(hiddenQuestionIds);

    final progress = _storage.getProgress(_activeCompanion.id, widget.deck.id);
    _currentIndex = progress.currentIndex.clamp(
      0,
      _questions.isEmpty ? 0 : _questions.length,
    );
  }

  Future<void> _onIndexChanged(int newIndex) async {
    _currentIndex = newIndex;
    if (newIndex < _questions.length) {
      final q = _questions[newIndex];
      await _storage.markQuestionSeen(
        companionId: _activeCompanion.id,
        deckId: widget.deck.id,
        questionId: q.id,
        newIndex: newIndex,
      );
    } else {
      // Reached the end
      final progress = _storage.getProgress(_activeCompanion.id, widget.deck.id);
      await _storage.saveProgress(
        progress.copyWith(currentIndex: newIndex, lastActive: DateTime.now()),
      );
    }
  }

  void _hideQuestion(Question question) async {
    await HapticService.heavy();
    await _storage.hideQuestion(question.id);

    setState(() {
      _loadDeckData();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Question hidden from deck'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await _storage.unhideQuestion(question.id);
              if (mounted) {
                setState(() {
                  _loadDeckData();
                });
              }
            },
          ),
        ),
      );
    }
  }

  void _resetProgress() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Progress?',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Reset question progress with ${_activeCompanion.name} for this pack back to Card 1?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _storage.resetProgress(_activeCompanion.id, widget.deck.id);
              await HapticService.selection();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                setState(() {
                  _resetVersion++;
                  _loadDeckData();
                });
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.deck.title,
              style: GoogleFonts.newsreader(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            GestureDetector(
              onTap: () async {
                await CompanionSheet.show(context);
                if (mounted) {
                  setState(() {
                    _loadDeckData();
                  });
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'with ${_activeCompanion.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.deck.accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: widget.deck.accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) async {
              if (val == 'reset') {
                _resetProgress();
              } else if (val == 'switch_person') {
                await CompanionSheet.show(context);
                if (mounted) {
                  setState(() {
                    _resetVersion++;
                    _loadDeckData();
                  });
                }
              } else if (val == 'export') {
                await DeckExchangeService.shareDeckFile(context, widget.deck);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch_person',
                child: Row(
                  children: [
                    const Icon(Icons.people_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Talking with ${_activeCompanion.name}...',
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
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reset progress for this person',
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
      body: SafeArea(
        child: TactileCardStack(
          key: ValueKey('${widget.deck.id}_${_activeCompanion.id}_$_resetVersion'),
          questions: _questions,
          initialIndex: _currentIndex,
          deckTitle: widget.deck.title,
          accentColor: widget.deck.accentColor,
          companionName: _activeCompanion.name,
          onIndexChanged: _onIndexChanged,
          onHideQuestion: _hideQuestion,
          onResetDeck: () async {
            await _storage.resetProgress(_activeCompanion.id, widget.deck.id);
            setState(() {
              _resetVersion++;
              _loadDeckData();
            });
          },
        ),
      ),
    );
  }
}
