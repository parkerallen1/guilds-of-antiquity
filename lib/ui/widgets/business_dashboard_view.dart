import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/business_model.dart';
import '../../providers/game_provider.dart';
import '../../services/ticker_service.dart'; // For tick provider

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
          Card(
            color: Colors.grey[900],
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(_getIcon(business.type), size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    business.name,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    business.description,
                    style: const TextStyle(color: Colors.grey),
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
          ),

          const SizedBox(height: 24),
          Text(
            "Management",
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 20),
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
        const Text(
          "Select Duration",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          "${_selectedDurationHours.toInt()} Hours",
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
          _getEstimateText(business, _selectedDurationHours.toInt()),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
          onPressed: () {
            ref
                .read(gameProvider.notifier)
                .startBusinessProduction((_selectedDurationHours * 60).toInt());
          },
          child: const Text(
            "Start Production",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
        const Text(
          "Production in Progress",
          style: TextStyle(color: Colors.amber, fontSize: 18),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          minHeight: 12,
        ),
        const SizedBox(height: 8),
        Text(
          "Time Remaining: ${_formatDuration(remaining)}",
          style: const TextStyle(color: Colors.white),
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
        const Text(
          "Production Complete!",
          style: TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          ),
          onPressed: () {
            ref.read(gameProvider.notifier).claimBusinessReward(DateTime.now());
          },
          child: const Text(
            "Claim Rewards",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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

    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Level $currentLevel",
                    style: const TextStyle(color: Colors.blueAccent),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: canAfford ? onUpgrade : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Upgrade"),
                  Text("$cost G", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
