import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';

class CustomDeckScreen extends StatefulWidget {
  final QuestionDeck? initialDeck;

  const CustomDeckScreen({super.key, this.initialDeck});

  @override
  State<CustomDeckScreen> createState() => _CustomDeckScreenState();
}

class _CustomDeckScreenState extends State<CustomDeckScreen> {
  final StorageService _storage = StorageService.instance;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<Question> _questions;

  @override
  void initState() {
    super.initState();
    final deck = widget.initialDeck;
    _titleController = TextEditingController(text: deck?.title ?? '');
    _descriptionController =
        TextEditingController(text: deck?.description ?? '');
    _questions = deck != null ? List.from(deck.questions) : [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAddQuestionDialog([Question? questionToEdit, int? editIndex]) {
    final controller =
        TextEditingController(text: questionToEdit?.text ?? '');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          questionToEdit == null ? 'Add Question' : 'Edit Question',
          style: GoogleFonts.newsreader(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your conversation starter...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (questionToEdit != null && editIndex != null) {
                    _questions[editIndex] = questionToEdit.copyWith(text: text);
                  } else {
                    final isCustom = widget.initialDeck?.isCustom ?? true;
                    _questions.add(
                      Question(
                        id: 'custom_${const Uuid().v4()}',
                        text: text,
                        deckId: widget.initialDeck?.id ?? 'custom_deck',
                        isCustom: isCustom,
                      ),
                    );
                  }
                });
                HapticService.light();
                Navigator.of(context).pop();
              }
            },
            child: Text(questionToEdit == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDeck() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your pack')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    final isCustom = widget.initialDeck?.isCustom ?? true;
    final deckId = widget.initialDeck?.id ?? 'custom_${const Uuid().v4()}';
    final updatedQuestions = _questions
        .map((q) => q.copyWith(deckId: deckId))
        .toList();

    final deck = QuestionDeck(
      id: deckId,
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : (isCustom ? 'Personal questions created by you.' : ''),
      icon: widget.initialDeck?.icon ?? Icons.chat_bubble_outline,
      accentColor: widget.initialDeck?.accentColor ?? const Color(0xFFD97736),
      questions: updatedQuestions,
      isCustom: isCustom,
      version: widget.initialDeck?.version ?? 1,
    );

    await _storage.saveDeck(deck);
    await HapticService.selection();

    if (mounted) {
      Navigator.of(context).pop(deck);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialDeck == null
              ? 'New Pack'
              : (widget.initialDeck!.isCustom ? 'Edit Pack' : 'Customize Pack'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: FilledButton(
              onPressed: _saveDeck,
              child: const Text('Save Pack'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          TextField(
            controller: _titleController,
            style: GoogleFonts.newsreader(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Pack Title',
              hintText: 'e.g., Road Trip with Sarah',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'A short note about what this pack is for...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Questions (${_questions.length})',
                  style: GoogleFonts.newsreader(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () => _showAddQuestionDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Question'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_questions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Text(
                'No questions added yet. Tap "+ Add Question" to begin writing your own conversation starters.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    question.text,
                    style: const TextStyle(fontSize: 15),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () =>
                            _showAddQuestionDialog(question, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            _questions.removeAt(index);
                          });
                          HapticService.light();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
