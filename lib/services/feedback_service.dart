import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

enum FeedbackType { success, error, warning, info, gold, xp, damage }

class FeedbackRequest {
  final FeedbackType type;
  final String message;
  final dynamic data; // For coordinates or other data

  FeedbackRequest(this.type, this.message, [this.data]);
}

class FeedbackService {
  final _feedbackController = StreamController<FeedbackRequest>.broadcast();
  final _shakeController = StreamController<void>.broadcast();

  Stream<FeedbackRequest> get feedbackStream => _feedbackController.stream;
  Stream<void> get shakeStream => _shakeController.stream;

  // Haptics
  Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  // Visuals
  void showFloatingText(String text, FeedbackType type, {dynamic position}) {
    _feedbackController.add(FeedbackRequest(type, text, position));
  }

  void triggerShake() {
    _shakeController.add(null);
  }

  void dispose() {
    _feedbackController.close();
    _shakeController.close();
  }
}
