import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/feedback_service.dart';

class GameFeedbackWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const GameFeedbackWrapper({super.key, required this.child});

  @override
  ConsumerState<GameFeedbackWrapper> createState() =>
      _GameFeedbackWrapperState();
}

class _GameFeedbackWrapperState extends ConsumerState<GameFeedbackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Listen to feedback streams
    final feedbackService = ref.read(feedbackServiceProvider);

    feedbackService.shakeStream.listen((_) {
      _triggerShake();
    });

    feedbackService.feedbackStream.listen((request) {
      _showFloatingText(request);
    });
  }

  void _triggerShake() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  void _showFloatingText(FeedbackRequest request) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    // Determine color based on type
    Color color = Colors.white;
    switch (request.type) {
      case FeedbackType.gold:
        color = Colors.amber;
        break;
      case FeedbackType.xp:
        color = Colors.cyan;
        break;
      case FeedbackType.damage:
        color = Colors.red;
        break;
      case FeedbackType.success:
        color = Colors.green;
        break;
      case FeedbackType.error:
        color = Colors.red;
        break;
      default:
        color = Colors.white;
    }

    // Determine position (default to center or tap position if provided)
    Offset position = request.data is Offset
        ? request.data
        : MediaQuery.of(context).size.center(Offset.zero);

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy,
        child: Material(
          color: Colors.transparent,
          child:
              Text(
                    request.message,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                    ),
                  )
                  .animate()
                  .moveY(
                    begin: 0,
                    end: -50,
                    duration: 800.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(delay: 400.ms, duration: 400.ms),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 800), () {
      entry.remove();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = sin(_shakeController.value * pi * 4) * 5;
        final dy = cos(_shakeController.value * pi * 4) * 5;
        return Transform.translate(
          offset: _shakeController.isAnimating ? Offset(dx, dy) : Offset.zero,
          child: widget.child,
        );
      },
    );
  }
}
