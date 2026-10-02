import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:konfide/core/models/question.dart';

class CardShareDialog extends StatefulWidget {
  final Question question;
  final String deckTitle;

  const CardShareDialog({
    super.key,
    required this.question,
    required this.deckTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required Question question,
    required String deckTitle,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CardShareDialog(
        question: question,
        deckTitle: deckTitle,
      ),
    );
  }

  @override
  State<CardShareDialog> createState() => _CardShareDialogState();
}

class _CardShareDialogState extends State<CardShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareImage() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/konfide_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: '"${widget.question.text}"\n\n— via Konfide',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating card image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareText() async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text:
            '"${widget.question.text}"\n\n— from the "${widget.deckTitle}" deck in Konfide',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shareable Card Container
            RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380, minHeight: 340),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF28211D),
                      Color(0xFF1E1714),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFFD97736).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App branding header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97736).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: Color(0xFFE5A638),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KONFIDE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                            color: const Color(0xFFE5A638),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Deck title badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.deckTitle.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Question Text
                    Text(
                      widget.question.text,
                      style: GoogleFonts.newsreader(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: const Color(0xFFF9F6F0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Subtitle
                    Text(
                      'Conversations that matter',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Wrap
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _isExporting ? null : _shareImage,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.photo_outlined, size: 18),
                  label: const Text('Share Card Image'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _shareText,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Share Text'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
