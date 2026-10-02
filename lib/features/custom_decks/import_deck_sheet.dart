import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/deck.dart';
import 'package:konfide/core/services/deck_exchange_service.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/core/services/storage_service.dart';

class ImportDeckSheet extends StatefulWidget {
  const ImportDeckSheet({super.key});

  static Future<QuestionDeck?> show(BuildContext context) {
    return showModalBottomSheet<QuestionDeck>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImportDeckSheet(),
    );
  }

  @override
  State<ImportDeckSheet> createState() => _ImportDeckSheetState();
}

class _ImportDeckSheetState extends State<ImportDeckSheet> {
  final StorageService _storage = StorageService.instance;
  final TextEditingController _textController = TextEditingController();

  QuestionDeck? _parsedDeck;
  String? _errorMessage;
  bool _isLoading = false;
  bool _showRawJsonField = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseContent(String content) {
    setState(() {
      _errorMessage = null;
      _parsedDeck = null;
    });

    try {
      final deck = DeckExchangeService.parseAndValidateDeckJson(content);
      setState(() {
        _parsedDeck = deck;
      });
      HapticService.selection();
    } catch (e) {
      setState(() {
        _errorMessage = e is FormatException ? e.message : e.toString();
      });
      HapticService.medium();
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isLoading = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final content = await file.xFile.readAsString();
        _textController.text = content;
        _parseContent(content);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not read file: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        setState(() {
          _errorMessage = 'Clipboard is empty. Copy a pack JSON first.';
        });
      } else {
        _textController.text = text;
        _parseContent(text);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access clipboard: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmImport() async {
    final deck = _parsedDeck;
    if (deck == null) return;

    await _storage.importDeck(deck);
    await HapticService.selection();

    if (mounted) {
      Navigator.of(context).pop(deck);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported "${deck.title}" successfully!'),
          backgroundColor: deck.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Import Question Pack',
                  style: GoogleFonts.newsreader(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select a .json pack file or paste pack data directly from your clipboard.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons (File Picker & Clipboard)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.file_open_outlined),
                    label: const Text('Pick .json File'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded),
                    label: const Text('Paste JSON'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Collapsible Manual Text Field Toggle
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showRawJsonField = !_showRawJsonField;
                  });
                },
                icon: Icon(
                  _showRawJsonField
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  _showRawJsonField ? 'Hide raw JSON' : 'Or type / edit raw JSON',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),

            if (_showRawJsonField) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _textController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: '{\n  "title": "My Pack",\n  "questions": ["..."]\n}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (val) => _parseContent(val),
              ),
            ],

            // Error Display
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Valid Deck Preview
            if (_parsedDeck != null) ...[
              const SizedBox(height: 20),
              Text(
                'Pack Preview',
                style: GoogleFonts.newsreader(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: _parsedDeck!.accentColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _parsedDeck!.accentColor
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _parsedDeck!.icon,
                              color: _parsedDeck!.accentColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _parsedDeck!.title,
                                  style: GoogleFonts.newsreader(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _parsedDeck!.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _parsedDeck!.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _parsedDeck!.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.format_quote_rounded,
                              size: 16, color: _parsedDeck!.accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '${_parsedDeck!.questions.length} questions included',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _parsedDeck!.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _confirmImport,
                icon: const Icon(Icons.download_done_rounded),
                label: Text(
                  'Import "${_parsedDeck!.title}"',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
