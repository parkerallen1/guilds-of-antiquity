import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/hero_model.dart';
import '../../providers/quest_provider.dart';

class QuestStatusBox extends ConsumerStatefulWidget {
  final HeroModel hero;

  const QuestStatusBox({super.key, required this.hero});

  @override
  ConsumerState<QuestStatusBox> createState() => _QuestStatusBoxState();
}

class _QuestStatusBoxState extends ConsumerState<QuestStatusBox> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  String _currentLore = "Adventuring...";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant QuestStatusBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hero.status != oldWidget.hero.status ||
        widget.hero.questCompletesAt != oldWidget.hero.questCompletesAt) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.hero.status == HeroStatus.questing &&
        widget.hero.questCompletesAt != null) {
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    }
  }

  void _updateTime() {
    if (widget.hero.questCompletesAt == null) return;
    final now = DateTime.now();
    final remaining = widget.hero.questCompletesAt!.difference(now);

    if (remaining.isNegative) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _remaining = Duration.zero;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _remaining = remaining;
        _updateLore();
      });
    }
  }

  void _updateLore() {
    final questService = ref.read(questServiceProvider);
    final quest = questService.getQuestById(widget.hero.activeQuestId ?? "");
    if (quest == null) {
      _currentLore = "Adventuring...";
      return;
    }

    if (quest.lore.isEmpty) {
      _currentLore = "Exploring ${quest.title}...";
      return;
    }

    final totalDuration = Duration(seconds: quest.durationSeconds);
    // Avoid division by zero
    if (totalDuration.inSeconds == 0) return;

    final progress =
        1.0 - (_remaining.inMilliseconds / totalDuration.inMilliseconds);
    final clampedProgress = progress.clamp(0.0, 0.99);
    final index = (clampedProgress * quest.lore.length).floor();

    if (index >= 0 && index < quest.lore.length) {
      _currentLore = quest.lore[index];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questResults = ref.watch(questResultProvider);
    final result = questResults[widget.hero.id];

    if (widget.hero.status == HeroStatus.questing) {
      return _buildQuestingStatus();
    } else if (result != null) {
      return _buildResultStatus(result);
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuestingStatus() {
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "QUEST IN PROGRESS",
            style: GoogleFonts.cinzel(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier', // Monospace for timer
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentLore,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatus(QuestResult result) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.success ? Colors.green : Colors.red,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (result.success ? Colors.green : Colors.red).withOpacity(
              0.2,
            ),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.success ? "VICTORY!" : "DEFEAT",
            style: GoogleFonts.cinzel(
              color: result.success ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.questTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (result.success) ...[
            _buildRewardRow(
              FontAwesomeIcons.coins,
              "${result.goldGained} Gold",
              Colors.amber,
            ),
            _buildRewardRow(
              FontAwesomeIcons.star,
              "${result.xpGained} XP",
              Colors.blue,
            ),
            if (result.itemsGained.isNotEmpty)
              ...result.itemsGained.map(
                (item) => _buildRewardRow(
                  FontAwesomeIcons.gem,
                  item,
                  Colors.purpleAccent,
                ),
              ),
          ] else
            const Text(
              "Better luck next time...",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () {
                ref.read(questResultProvider.notifier).update((state) {
                  final newState = Map<String, QuestResult>.from(state);
                  newState.remove(widget.hero.id);
                  return newState;
                });
              },
              child: const Text(
                "Dismiss",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
