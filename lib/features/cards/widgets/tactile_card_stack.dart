import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:konfide/core/models/question.dart';
import 'package:konfide/core/services/haptic_service.dart';
import 'package:konfide/features/cards/widgets/tactile_card.dart';

class TactileCardStack extends StatefulWidget {
  final List<Question> questions;
  final int initialIndex;
  final String deckTitle;
  final Color accentColor;
  final String companionName;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<Question> onDeleteQuestion;
  final VoidCallback? onResetDeck;

  const TactileCardStack({
    super.key,
    required this.questions,
    this.initialIndex = 0,
    required this.deckTitle,
    required this.accentColor,
    required this.companionName,
    required this.onIndexChanged,
    required this.onDeleteQuestion,
    this.onResetDeck,
  });

  @override
  State<TactileCardStack> createState() => _TactileCardStackState();
}

class _TactileCardStackState extends State<TactileCardStack>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  Offset _dragOffset = Offset.zero;
  bool _hapticTriggeredForSwipe = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, math.max(0, widget.questions.length - 1));
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant TactileCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      _currentIndex = widget.initialIndex.clamp(0, math.max(0, widget.questions.length - 1));
    } else if (widget.questions.isEmpty) {
      _currentIndex = 0;
    } else if (_currentIndex >= widget.questions.length) {
      _currentIndex = math.max(0, widget.questions.length - 1);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_currentIndex < widget.questions.length) {
      setState(() {
        _currentIndex++;
      });
      HapticService.medium();
      widget.onIndexChanged(_currentIndex);
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      HapticService.light();
      widget.onIndexChanged(_currentIndex);
    }
  }

  void _animateOffScreen({required bool toLeft}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = toLeft ? -screenWidth * 1.3 : screenWidth * 1.3;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / 1000,
      end: (toLeft ? -0.35 : 0.35),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward(from: 0.0).then((_) {
      _animController.reset();
      _dragOffset = Offset.zero;
      _hapticTriggeredForSwipe = false;
      if (toLeft) {
        _nextCard();
      } else {
        _prevCard();
      }
    });
  }

  void _springBack() {
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _rotationAnimation = Tween<double>(
      begin: _dragOffset.dx / 1000,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _animController.forward(from: 0.0).then((_) {
      _animController.reset();
      setState(() {
        _dragOffset = Offset.zero;
        _hapticTriggeredForSwipe = false;
      });
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });

    if (_dragOffset.dx.abs() > 80 && !_hapticTriggeredForSwipe) {
      _hapticTriggeredForSwipe = true;
      HapticService.light();
    } else if (_dragOffset.dx.abs() < 80) {
      _hapticTriggeredForSwipe = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final velocityX = details.velocity.pixelsPerSecond.dx;
    if (_dragOffset.dx < -100 || velocityX < -700) {
      // Swiped Left -> Next Card
      _animateOffScreen(toLeft: true);
    } else if ((_dragOffset.dx > 100 || velocityX > 700) && _currentIndex > 0) {
      // Swiped Right -> Previous Card
      _animateOffScreen(toLeft: false);
    } else {
      _springBack();
    }
  }

  Widget _buildDeckCompletedView() {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Deck Completed!',
              style: GoogleFonts.newsreader(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have explored all questions in this pack with ${widget.companionName}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                widget.onResetDeck?.call();
                setState(() => _currentIndex = 0);
                widget.onIndexChanged(0);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start Over with this Pack'),
              style: FilledButton.styleFrom(
                backgroundColor: widget.accentColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Decks'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available in this deck.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final isFinished = _currentIndex >= widget.questions.length;

    if (isFinished) {
      return _buildDeckCompletedView();
    }

    final currentQuestion = widget.questions[_currentIndex];
    final hasNext = _currentIndex + 1 < widget.questions.length;
    final hasNextNext = _currentIndex + 2 < widget.questions.length;

    return Column(
      children: [
        // Top Counter & Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Card ${_currentIndex + 1} of ${widget.questions.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.questions.length,
                  backgroundColor:
                      widget.accentColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),

        // Interactive Card Stack Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Underneath Card 2 (Depth 2)
                  if (hasNextNext)
                    Transform.translate(
                      offset: const Offset(0, 24),
                      child: Transform.scale(
                        scale: 0.88,
                        child: Opacity(
                          opacity: 0.5,
                          child: TactileCard(
                            question: widget.questions[_currentIndex + 2],
                            deckTitle: widget.deckTitle,
                            accentColor: widget.accentColor,
                          ),
                        ),
                      ),
                    ),

                  // Underneath Card 1 (Depth 1)
                  if (hasNext)
                    Transform.translate(
                      offset: const Offset(0, 12),
                      child: Transform.scale(
                        scale: 0.94,
                        child: Opacity(
                          opacity: 0.8,
                          child: TactileCard(
                            question: widget.questions[_currentIndex + 1],
                            deckTitle: widget.deckTitle,
                            accentColor: widget.accentColor,
                          ),
                        ),
                      ),
                    ),

                  // Top Interactive Card
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final offset = _animController.isAnimating
                          ? _slideAnimation.value
                          : _dragOffset;
                      final rotation = _animController.isAnimating
                          ? _rotationAnimation.value
                          : _dragOffset.dx / 1200;

                      return Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle: rotation,
                          child: GestureDetector(
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: TactileCard(
                              key: ValueKey(currentQuestion.id),
                              question: currentQuestion,
                              deckTitle: widget.deckTitle,
                              accentColor: widget.accentColor,
                              onDeleteQuestion: () {
                                widget.onDeleteQuestion(currentQuestion);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // Bottom Navigation Bar: Prev, Card Counter, Next
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Card Button
              IconButton.filledTonal(
                tooltip: 'Previous question',
                onPressed: _currentIndex > 0 ? _prevCard : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),


              // Next Card Button
              IconButton.filled(
                tooltip: 'Next question',
                onPressed: _nextCard,
                icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
