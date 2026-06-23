import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/hive_service.dart';
import '../../models/museum_state.dart';
import '../../models/item_model.dart';
import '../../data/museum_items.dart';
import '../../data/museum_sets.dart';
import '../widgets/retro_widgets.dart';

class MuseumScreen extends ConsumerWidget {
  const MuseumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'THE MUSEUM',
          style: GoogleFonts.vt323(
            color: Colors.amber,
            fontSize: 26,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
      ),
      body: ValueListenableBuilder<Box<MuseumState>>(
        valueListenable: HiveService.museumBox.listenable(),
        builder: (context, box, _) {
          final museumState =
              box.get('state') ??
              MuseumState(unlockedItemIds: [], unlockedEndings: []);
          final unlockedIds = Set<String>.from(museumState.unlockedItemIds);

          // Group items
          final era1Items = [
            'whispering_stone_fragment',
            'corrupted_root',
            'bandit_badge',
          ];
          final era2Items = ['frozen_heart', 'void_essence', 'ash_king_head'];
          final era3Items = ['thrall_helmet', 'crown_eclipse', 'shard_reality'];
          final legendaryItems = [
            'abdication_ring',
            'tear_bride',
            'thorne_dagger',
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(museumState.completionPercentage),
                const SizedBox(height: 20),
                _buildSetRewards(unlockedIds),
                const SizedBox(height: 8),
                _buildSection("AGE OF IRON", era1Items, unlockedIds),
                _buildSection("AGE OF SHADOWS", era2Items, unlockedIds),
                _buildSection("AGE OF ARCANUM", era3Items, unlockedIds),
                _buildSection(
                  "LEGENDARY ARTIFACTS",
                  legendaryItems,
                  unlockedIds,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(double percentage) {
    return RetroPanel(
      backgroundColor: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.buildingColumns,
            color: Colors.amber,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURATOR'S COLLECTION",
                  style: GoogleFonts.vt323(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "COMPLETION: ${(percentage * 100).toStringAsFixed(1)}%",
                  style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRewards(Set<String> unlockedIds) {
    final unlocked = unlockedIds.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "COLLECTION REWARDS",
          style: GoogleFonts.vt323(
            color: Colors.cyanAccent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        for (final set in MuseumSets.all)
          _buildSetRewardTile(set, unlocked),
      ],
    );
  }

  Widget _buildSetRewardTile(MuseumSet set, List<String> unlockedIds) {
    final unlocked = set.unlockedCount(unlockedIds);
    final total = set.itemIds.length;
    final complete = unlocked >= total;
    return RetroPanel(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      backgroundColor: Colors.grey[900],
      borderWidth: 2,
      bevelWidth: 2,
      highlightColor:
          (complete ? Colors.amber : Colors.transparent).withValues(alpha: 0.18),
      child: Row(
        children: [
          Icon(
            complete ? FontAwesomeIcons.medal : FontAwesomeIcons.lock,
            color: complete ? Colors.amber : Colors.grey[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${set.title} → ${set.artifactName}".toUpperCase(),
                  style: GoogleFonts.vt323(color: Colors.white, fontSize: 17),
                ),
                Text(
                  set.rewardDescription,
                  style: GoogleFonts.pixelifySans(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                RetroProgressBar(
                  value: total == 0 ? 0 : unlocked / total,
                  progressColor: complete ? Colors.amber : Colors.cyanAccent,
                  height: 10,
                  segments: total,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (complete)
            const Icon(FontAwesomeIcons.check, color: Colors.green, size: 16)
          else
            Text(
              "$unlocked/$total",
              style: GoogleFonts.vt323(color: Colors.grey[400], fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> itemIds,
    Set<String> unlockedIds,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: GoogleFonts.vt323(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: itemIds.length,
          itemBuilder: (context, index) {
            final itemId = itemIds[index];
            final item = MuseumItems.getById(itemId);
            final isUnlocked = unlockedIds.contains(itemId);

            if (item == null) return const SizedBox.shrink();

            return _buildItemCard(item, isUnlocked);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildItemCard(Item item, bool isUnlocked) {
    final Color rarityColor = _getRarityColor(item.rarity);
    return RetroPanel(
      inset: true,
      backgroundColor: isUnlocked ? Colors.grey[900] : const Color(0xFF0D0D0D),
      outlineColor: isUnlocked ? rarityColor : Colors.black,
      borderWidth: 1.5,
      bevelWidth: 1.5,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: isUnlocked
                  ? (item.imagePath != null
                      ? Image.asset(item.imagePath!, fit: BoxFit.contain)
                      : Icon(
                          _getIconForSlot(item.slot),
                          color: rarityColor,
                          size: 32,
                        ))
                  : Icon(
                      Icons.lock,
                      color: Colors.grey[700],
                      size: 24,
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            color: Colors.black54,
            child: Text(
              isUnlocked ? item.name.toUpperCase() : "???",
              style: GoogleFonts.vt323(
                color: isUnlocked ? Colors.white : Colors.grey[600],
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blueAccent;
      case ItemRarity.epic:
        return Colors.purpleAccent;
      case ItemRarity.legendary:
        return Colors.amber;
      case ItemRarity.quest:
        return Colors.tealAccent;
    }
  }

  IconData _getIconForSlot(ItemSlot slot) {
    switch (slot) {
      case ItemSlot.mainHand:
        return FontAwesomeIcons.khanda;
      case ItemSlot.offHand:
        return FontAwesomeIcons.shieldHalved;
      case ItemSlot.armor:
        return FontAwesomeIcons.shirt;
      case ItemSlot.accessory:
        return FontAwesomeIcons.ring;
      case ItemSlot.trophy:
        return FontAwesomeIcons.trophy;
    }
  }
}
