import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/hive_service.dart';
import '../../models/museum_state.dart';
import '../../models/item_model.dart';
import '../../data/museum_items.dart';

class MuseumScreen extends ConsumerWidget {
  const MuseumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          'The Museum',
          style: GoogleFonts.cinzel(color: Colors.amber),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
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
                const SizedBox(height: 24),
                _buildSection("Age of Iron", era1Items, unlockedIds),
                _buildSection("Age of Shadows", era2Items, unlockedIds),
                _buildSection("Age of Arcanum", era3Items, unlockedIds),
                _buildSection(
                  "Legendary Artifacts",
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.buildingColumns,
            color: Colors.amber,
            size: 40,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Curator's Collection",
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Completion: ${(percentage * 100).toStringAsFixed(1)}%",
                style: GoogleFonts.lato(color: Colors.grey),
              ),
            ],
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
            style: GoogleFonts.cinzel(
              color: Colors.amber,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
            final isUnlocked = unlockedIds.contains(
              itemId,
            ); // Use name matching if IDs in json were names, but I used IDs in MuseumItems.
            // Wait, in quests.json I put "specialItemReward": "Whispering Stone Fragment" (Name).
            // But MuseumItems uses IDs like "whispering_stone_fragment".
            // The Quest logic needs to unlock by ID or Name.
            // The Quest logic currently likely uses the string in specialItemReward as the ID or Name.
            // I should check how the unlock logic works.
            // If it's not implemented yet, I need to implement it.
            // Assuming the unlock logic will use the Name to find the Item, then add the Item ID to the museum.

            // For display here:
            if (item == null) return const SizedBox.shrink();

            // Check if unlocked. The museum state stores IDs.
            // If the quest rewards "Whispering Stone Fragment" (Name), the logic that processes the reward
            // must find the item by Name in MuseumItems, get its ID, and add it to MuseumState.

            return _buildItemCard(item, isUnlocked);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildItemCard(Item item, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked
              ? _getRarityColor(item.rarity)
              : Colors.grey.withOpacity(0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
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
                            color: _getRarityColor(item.rarity),
                            size: 40,
                          ))
                  : Icon(
                      Icons.lock,
                      color: Colors.grey.withOpacity(0.3),
                      size: 30,
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.black54,
            child: Text(
              isUnlocked ? item.name : "???",
              style: GoogleFonts.cinzel(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
