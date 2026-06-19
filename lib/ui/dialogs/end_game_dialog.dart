import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/game_provider.dart';
import '../../models/item_model.dart';
import '../screens/history_screen.dart';
import '../widgets/retro_widgets.dart';

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
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: RetroPanel(
        backgroundColor: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "THE TURN OF THE AGE",
                style: GoogleFonts.vt323(
                  color: Colors.amber,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                "THE EMPIRE FALLS. ONLY A FEW RELICS CAN BE SAVED.",
                style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Vault Slots Header
            Text(
              "THE VAULT (${vaultItems.length}/$maxSlots)",
              style: GoogleFonts.vt323(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            // Vault Slots Container
            RetroPanel(
              inset: true,
              backgroundColor: const Color(0xFF0D0D0D),
              padding: const EdgeInsets.all(4),
              height: 96,
              child: vaultItems.isEmpty
                  ? Center(
                      child: Text(
                        "TAP INVENTORY TO SAVING ITEMS",
                        style: GoogleFonts.vt323(color: Colors.grey[600], fontSize: 14, letterSpacing: 0.5),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: vaultItems.length,
                      itemBuilder: (context, index) {
                        final item = vaultItems[index];
                        final rarityColor = _getRarityColor(item.rarity);
                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(gameProvider.notifier)
                                .removeFromVault(item);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: RetroPanel(
                              backgroundColor: Colors.grey[850],
                              outlineColor: rarityColor,
                              borderWidth: 1.5,
                              bevelWidth: 1.5,
                              padding: const EdgeInsets.all(8),
                              width: 80,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getItemIcon(item.slot),
                                    color: rarityColor,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.name.toUpperCase(),
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Inventory Header
            Text(
              "AVAILABLE INVENTORY",
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            // Inventory Container
            Expanded(
              child: RetroPanel(
                inset: true,
                backgroundColor: const Color(0xFF0D0D0D),
                padding: const EdgeInsets.all(6),
                child: inventory.isEmpty
                    ? Center(
                        child: Text(
                          "INVENTORY EMPTY",
                          style: GoogleFonts.vt323(color: Colors.grey[600], fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: inventory.length,
                        separatorBuilder: (context, index) {
                          final item = inventory[index];
                          final isInVault = vaultItems.any((i) => i.id == item.id);
                          return isInVault ? const SizedBox.shrink() : const SizedBox(height: 6);
                        },
                        itemBuilder: (context, index) {
                          final item = inventory[index];
                          final isInVault = vaultItems.any((i) => i.id == item.id);

                          if (isInVault) {
                            return const SizedBox.shrink(); // Hide if already in vault
                          }

                          final rarityColor = _getRarityColor(item.rarity);

                          return RetroPanel(
                            backgroundColor: Colors.grey[900],
                            borderWidth: 1.5,
                            bevelWidth: 1.5,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                RetroPanel(
                                  width: 36,
                                  height: 36,
                                  padding: EdgeInsets.zero,
                                  backgroundColor: const Color(0xFF0D0D0D),
                                  borderWidth: 1.0,
                                  bevelWidth: 1.0,
                                  outlineColor: rarityColor,
                                  child: Center(
                                    child: Icon(
                                      _getItemIcon(item.slot),
                                      color: rarityColor,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name.toUpperCase(),
                                        style: GoogleFonts.vt323(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        item.rarity.name.toUpperCase(),
                                        style: GoogleFonts.pixelifySans(
                                          color: rarityColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RetroButton(
                                  backgroundColor: Colors.cyan[700]!,
                                  enabled: vaultItems.length < maxSlots,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  onPressed: vaultItems.length < maxSlots
                                      ? () {
                                          ref
                                              .read(gameProvider.notifier)
                                              .addToVault(item);
                                        }
                                      : null,
                                  child: Icon(
                                    FontAwesomeIcons.arrowUp,
                                    color: vaultItems.length < maxSlots ? Colors.white : Colors.grey[400],
                                    size: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Reset Button
            RetroButton(
              backgroundColor: Colors.red[900]!,
              onPressed: () async {
                // Confirm dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    shape: const Border(), // sharp border
                    title: Text(
                      "WARNING",
                      style: GoogleFonts.vt323(
                        color: Colors.redAccent,
                        fontSize: 24,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      "THIS WILL DELETE ALL HEROES, GOLD, AND BUILDINGS. ONLY VAULT ITEMS WILL PERSIST. ARE YOU SURE?",
                      style: GoogleFonts.pixelifySans(color: Colors.white70, fontSize: 12),
                    ),
                    actions: [
                      RetroButton(
                        backgroundColor: Colors.grey[800]!,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "CANCEL",
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RetroButton(
                        backgroundColor: Colors.red[900]!,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          "TRANSCEND",
                          style: GoogleFonts.vt323(color: Colors.white, fontSize: 16),
                        ),
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
              child: Center(
                child: Text(
                  "TRANSCEND TIME",
                  style: GoogleFonts.vt323(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
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
}
