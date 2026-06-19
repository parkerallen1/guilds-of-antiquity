import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/business_model.dart';
import '../../providers/game_provider.dart';
import 'retro_widgets.dart';

class BusinessSelectionView extends ConsumerStatefulWidget {
  const BusinessSelectionView({super.key});

  @override
  ConsumerState<BusinessSelectionView> createState() =>
      _BusinessSelectionViewState();
}

class _BusinessSelectionViewState extends ConsumerState<BusinessSelectionView> {
  BusinessType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (_selectedType == null
                ? "CHOOSE YOUR ENTERPRISE"
                : "SELECT INITIAL UPGRADE").toUpperCase(),
            style: GoogleFonts.vt323(
              color: Colors.amber,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            (_selectedType == null
                ? "Select a business to manage for this Era."
                : "Choose a specialization for your ${_getBusinessName(_selectedType!)}.").toUpperCase(),
            style: GoogleFonts.pixelifySans(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _selectedType == null
                ? _buildTypeSelection()
                : _buildUpgradeSelection(),
          ),
        ],
      ),
    );
  }

  String _getBusinessName(BusinessType type) {
    switch (type) {
      case BusinessType.farm:
        return 'Farm';
      case BusinessType.mine:
        return 'Mine';
      case BusinessType.lodge:
        return 'Lodge';
    }
  }

  Widget _buildTypeSelection() {
    return ListView(
      children: [
        _buildTypeCard(
          BusinessType.farm,
          FontAwesomeIcons.wheatAwn,
          "The Farm",
          "Produces Items and Gold. A balanced choice.",
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          BusinessType.mine,
          FontAwesomeIcons.gem,
          "The Mine",
          "Produces massive amounts of Gold.",
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          BusinessType.lodge,
          FontAwesomeIcons.campground,
          "Hunter's Lodge",
          "Scouts for rare Quests and Information.",
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    BusinessType type,
    IconData icon,
    String title,
    String description,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: RetroPanel(
        backgroundColor: Colors.grey[850],
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: Colors.amber),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.vt323(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description.toUpperCase(),
                    style: GoogleFonts.pixelifySans(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeSelection() {
    final upgrades = _getUpgradesForType(_selectedType!);
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _buildUpgradeCard(upgrades[0]),
              const SizedBox(height: 16),
              _buildUpgradeCard(upgrades[1]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RetroButton(
          backgroundColor: Colors.grey[800]!,
          onPressed: () {
            setState(() {
              _selectedType = null;
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "BACK",
            style: GoogleFonts.vt323(color: Colors.white, fontSize: 16, letterSpacing: 1.0),
          ),
        ),
      ],
    );
  }

  List<BusinessUpgrade> _getUpgradesForType(BusinessType type) {
    switch (type) {
      case BusinessType.farm:
        return [BusinessUpgrade.fertilizer, BusinessUpgrade.marketStall];
      case BusinessType.mine:
        return [BusinessUpgrade.deepShafts, BusinessUpgrade.conveyorBelt];
      case BusinessType.lodge:
        return [BusinessUpgrade.scouts, BusinessUpgrade.network];
    }
  }

  Widget _buildUpgradeCard(BusinessUpgrade upgrade) {
    return GestureDetector(
      onTap: () {
        _confirmSelection(upgrade);
      },
      child: RetroPanel(
        backgroundColor: Colors.grey[850],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getUpgradeName(upgrade).toUpperCase(),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getUpgradeDescription(upgrade).toUpperCase(),
              style: GoogleFonts.pixelifySans(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUpgradeName(BusinessUpgrade upgrade) {
    switch (upgrade) {
      case BusinessUpgrade.fertilizer:
        return "Fertilizer";
      case BusinessUpgrade.marketStall:
        return "Market Stall";
      case BusinessUpgrade.deepShafts:
        return "Deep Shafts";
      case BusinessUpgrade.conveyorBelt:
        return "Conveyor Belt";
      case BusinessUpgrade.scouts:
        return "Expert Scouts";
      case BusinessUpgrade.network:
        return "Spy Network";
    }
  }

  String _getUpgradeDescription(BusinessUpgrade upgrade) {
    switch (upgrade) {
      case BusinessUpgrade.fertilizer:
        return "+10% Item Quality from Farm.";
      case BusinessUpgrade.marketStall:
        return "+20% Gold from Farm products.";
      case BusinessUpgrade.deepShafts:
        return "+20% Gold Amount from Mine.";
      case BusinessUpgrade.conveyorBelt:
        return "+10% Production Speed.";
      case BusinessUpgrade.scouts:
        return "+20% Quest Rarity.";
      case BusinessUpgrade.network:
        return "+10% Quest Find Speed.";
    }
  }

  void _confirmSelection(BusinessUpgrade upgrade) {
    final business = Business(
      type: _selectedType!,
      upgrades: [upgrade],
      lastCollected: DateTime.now(), // Start timer now
    );
    ref.read(gameProvider.notifier).setBusiness(business);
  }
}
