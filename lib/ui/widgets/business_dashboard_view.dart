import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/business_model.dart';
import '../../providers/game_provider.dart';
import '../../services/ticker_service.dart'; // For tick provider
import 'retro_widgets.dart';

class BusinessDashboardView extends ConsumerStatefulWidget {
  final Business business;

  const BusinessDashboardView({super.key, required this.business});

  @override
  ConsumerState<BusinessDashboardView> createState() =>
      _BusinessDashboardViewState();
}

class _BusinessDashboardViewState extends ConsumerState<BusinessDashboardView> {
  double _selectedDurationHours = 4.0; // Default 4 hours

  @override
  Widget build(BuildContext context) {
    // Rebuild on tick to update progress bar
    ref.watch(tickProvider);

    final business = widget.business;
    final now = DateTime.now();

    // Determine State
    bool isProducing = business.productionFinishTime != null;
    bool isFinished =
        isProducing && now.isAfter(business.productionFinishTime!);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          RetroPanel(
            backgroundColor: Colors.grey[900],
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(_getIcon(business.type), size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  business.name.toUpperCase(),
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  business.description.toUpperCase(),
                  style: GoogleFonts.pixelifySans(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // State-based UI
                if (isFinished)
                  _buildFinishedState(context, ref, business)
                else if (isProducing)
                  _buildProducingState(context, ref, business, now)
                else
                  _buildIdleState(context, ref, business),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text(
            "MANAGEMENT",
            style: GoogleFonts.vt323(
              color: Colors.amber,
              fontSize: 24,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Upgrades
          Expanded(
            child: ListView(
              children: [
                _buildUpgradeTile(
                  context,
                  ref,
                  "Quantity",
                  "Increases the amount of rewards.",
                  business.amountLevel,
                  business.amountUpgradeCost,
                  FontAwesomeIcons.coins,
                  () => ref.read(gameProvider.notifier).upgradeBusinessAmount(),
                ),
                const SizedBox(height: 12),
                _buildUpgradeTile(
                  context,
                  ref,
                  "Quality",
                  "Improves the rarity/value of rewards.",
                  business.qualityLevel,
                  business.qualityUpgradeCost,
                  FontAwesomeIcons.star,
                  () =>
                      ref.read(gameProvider.notifier).upgradeBusinessQuality(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) {
    return Column(
      children: [
        Text(
          "SELECT DURATION",
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "${_selectedDurationHours.toInt()} HOURS",
          style: GoogleFonts.vt323(
            color: Colors.amber,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        Slider(
          value: _selectedDurationHours,
          min: 1.0,
          max: 24.0,
          divisions: 23,
          activeColor: Colors.amber,
          inactiveColor: Colors.grey[800],
          onChanged: (value) {
            setState(() {
              _selectedDurationHours = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(
          _getEstimateText(business, _selectedDurationHours.toInt()).toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 16),
        RetroButton(
          backgroundColor: Colors.amber,
          onPressed: () {
            ref
                .read(gameProvider.notifier)
                .startBusinessProduction((_selectedDurationHours * 60).toInt());
          },
          child: Text(
            "START PRODUCTION",
            style: GoogleFonts.vt323(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProducingState(
    BuildContext context,
    WidgetRef ref,
    Business business,
    DateTime now,
  ) {
    final finishTime = business.productionFinishTime!;
    final totalDuration = Duration(
      minutes: business.selectedDurationMinutes ?? 60,
    );
    final elapsed = totalDuration - finishTime.difference(now);
    final progress = (elapsed.inSeconds / totalDuration.inSeconds).clamp(
      0.0,
      1.0,
    );
    final remaining = finishTime.difference(now);

    return Column(
      children: [
        Text(
          "PRODUCTION IN PROGRESS",
          style: GoogleFonts.vt323(
            color: Colors.amber,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        RetroProgressBar(
          value: progress,
          progressColor: Colors.amber,
          backgroundColor: const Color(0xFF0D0D0D),
          height: 18,
          segmented: true,
          segments: 15,
        ),
        const SizedBox(height: 8),
        Text(
          "TIME REMAINING: ${_formatDuration(remaining)}",
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedState(
    BuildContext context,
    WidgetRef ref,
    Business business,
  ) {
    return Column(
      children: [
        Text(
          "PRODUCTION COMPLETE!",
          style: GoogleFonts.vt323(
            color: Colors.greenAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        RetroButton(
          backgroundColor: Colors.green[700]!,
          onPressed: () {
            ref.read(gameProvider.notifier).claimBusinessReward(DateTime.now());
          },
          child: Text(
            "CLAIM REWARDS",
            style: GoogleFonts.vt323(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  String _getEstimateText(Business business, int hours) {
    // Simple estimation text
    if (business.type == BusinessType.mine) {
      return "Estimated: High Gold output.";
    } else if (business.type == BusinessType.farm) {
      return "Estimated: Gold and potential Items.";
    } else if (business.type == BusinessType.lodge) {
      return "Estimated: Scouts will search for Quests.";
    }
    return "";
  }

  IconData _getIcon(BusinessType type) {
    switch (type) {
      case BusinessType.farm:
        return FontAwesomeIcons.wheatAwn;
      case BusinessType.mine:
        return FontAwesomeIcons.gem;
      case BusinessType.lodge:
        return FontAwesomeIcons.campground;
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "0s";
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return "${h}h ${m}m ${s}s";
    return "${m}m ${s}s";
  }

  Widget _buildUpgradeTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    int currentLevel,
    int cost,
    IconData icon,
    VoidCallback onUpgrade,
  ) {
    final gameState = ref.watch(gameProvider);
    final canAfford = gameState.gold >= cost;

    return RetroPanel(
      backgroundColor: Colors.grey[850],
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          RetroPanel(
            backgroundColor: Colors.grey[900],
            padding: const EdgeInsets.all(8),
            width: 48,
            height: 48,
            borderWidth: 1.5,
            bevelWidth: 1.5,
            child: Center(
              child: Icon(icon, color: Colors.cyanAccent, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "LEVEL $currentLevel",
                  style: GoogleFonts.vt323(color: Colors.cyanAccent, fontSize: 14),
                ),
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RetroButton(
            backgroundColor: canAfford ? Colors.green[700]! : Colors.grey[700]!,
            enabled: canAfford,
            onPressed: canAfford ? onUpgrade : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "UPGRADE",
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$cost G",
                  style: GoogleFonts.vt323(
                    color: canAfford ? Colors.amberAccent : Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
