import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../models/item_model.dart';
import '../screens/history_screen.dart';

class EndGameDialog extends ConsumerStatefulWidget {
  const EndGameDialog({super.key});

  @override
  ConsumerState<EndGameDialog> createState() => _EndGameDialogState();
}

class _EndGameDialogState extends ConsumerState<EndGameDialog> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final maxSlots = gameState.vaultCapacity;
    final vaultItems = gameState.vaultItems;
    final inventory = gameState.inventory;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.amber, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.maxFinite,
        height: 600,
        child: Column(
          children: [
            Text(
              "THE TURN OF THE AGE",
              style: GoogleFonts.cinzel(
                color: Colors.amber,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The Empire falls. Only a few relics can be saved.",
              style: GoogleFonts.lato(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Vault Slots
            Text(
              "THE VAULT (${vaultItems.length}/$maxSlots)",
              style: GoogleFonts.cinzel(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black54,
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: vaultItems.isEmpty
                  ? const Center(
                      child: Text(
                        "Drag items here or tap to remove",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: vaultItems.length,
                      itemBuilder: (context, index) {
                        final item = vaultItems[index];
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(gameProvider.notifier)
                                .removeFromVault(item);
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              border: Border.all(color: Colors.cyanAccent),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getItemIcon(item.slot),
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Inventory
            Text(
              "INVENTORY",
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    final isInVault = vaultItems.any((i) => i.id == item.id);

                    if (isInVault) {
                      return const SizedBox.shrink(); // Hide if already in vault
                    }

                    return ListTile(
                      leading: Icon(
                        _getItemIcon(item.slot),
                        color: Colors.grey,
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        item.rarity.name.toUpperCase(),
                        style: TextStyle(color: _getRarityColor(item.rarity)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.cyanAccent,
                        ),
                        onPressed: vaultItems.length < maxSlots
                            ? () {
                                ref
                                    .read(gameProvider.notifier)
                                    .addToVault(item);
                              }
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  // Confirm dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("WARNING"),
                      content: const Text(
                        "This will delete all Heroes, Gold, and Buildings. Only Vault items will persist. Are you sure?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("TRANSCEND"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close EndGameDialog
                    await ref.read(gameProvider.notifier).resetGame();

                    if (context.mounted) {
                      final newEra = ref.read(gameProvider).currentEraIndex;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(eraIndex: newEra),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  "TRANSCEND TIME",
                  style: GoogleFonts.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(ItemSlot slot) {
    switch (slot) {
      case ItemSlot.mainHand:
        return FontAwesomeIcons.khanda; // Sword-like
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

  Color _getRarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return Colors.grey;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.legendary:
        return Colors.orange;
      case ItemRarity.quest:
        return Colors.tealAccent;
    }
  }
}
