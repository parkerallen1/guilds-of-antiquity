import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../providers/hero_provider.dart';
import '../../models/hero_model.dart';
import '../../models/hero_class.dart';
import '../../utils/text_gen.dart';
import '../widgets/retro_widgets.dart';

class HeroCreationScreen extends ConsumerStatefulWidget {
  const HeroCreationScreen({super.key});

  @override
  ConsumerState<HeroCreationScreen> createState() => _HeroCreationScreenState();
}

class _HeroCreationScreenState extends ConsumerState<HeroCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedClass = 'Warrior';
  String _selectedPortrait = 'assets/images/heroes/male_warrior.png';

  // Stats
  int _strength = 0;
  int _speed = 0;
  int _hp = 0;
  int _luck = 0;
  bool _statsRolled = false;

  final List<String> _classes = ['Warrior', 'Ranger', 'Mage', 'Thief'];
  final List<String> _portraits = [
    'assets/images/heroes/angry dwarf.jpeg',
    'assets/images/heroes/barbarian.jpeg',
    'assets/images/heroes/blacksmith dwarf.jpeg',
    'assets/images/heroes/demon knight.jpeg',
    'assets/images/heroes/demon.jpeg',
    'assets/images/heroes/eyepatch dwarf.jpeg',
    'assets/images/heroes/female_mage_4.png',
    'assets/images/heroes/female_ranger_3.png',
    'assets/images/heroes/female_ranger_4.png',
    'assets/images/heroes/female_warrior_4.png',
    'assets/images/heroes/female_warrior_5.png',
    'assets/images/heroes/female_warrior.png',
    'assets/images/heroes/fire mage.jpeg',
    'assets/images/heroes/hooded thief.jpeg',
    'assets/images/heroes/male_mage_3.png',
    'assets/images/heroes/male_warrior.png',
    'assets/images/heroes/master thief.jpeg',
    'assets/images/heroes/monk.jpeg',
    'assets/images/heroes/old soldier.jpeg',
    'assets/images/heroes/paladin female.jpeg',
    'assets/images/heroes/raging orc.jpeg',
    'assets/images/heroes/rune warrior.jpeg',
    'assets/images/heroes/seer.jpeg',
    'assets/images/heroes/skeleton.jpeg',
    'assets/images/heroes/swamp witch.jpeg',
    'assets/images/heroes/thief masked.jpeg',
  ];

  // Class Stat Definitions
  final Map<String, Map<String, List<int>>> _classStats = {
    'Warrior': {
      'str': [7, 12],
      'spd': [3, 8],
      'hp': [70, 120],
      'luck': [0, 5],
    },
    'Ranger': {
      'str': [5, 10],
      'spd': [6, 11],
      'hp': [50, 100],
      'luck': [3, 8],
    },
    'Mage': {
      'str': [8, 13], // Magic Power
      'spd': [4, 9],
      'hp': [40, 80],
      'luck': [2, 7],
    },
    'Thief': {
      'str': [4, 9],
      'spd': [8, 13],
      'hp': [45, 90],
      'luck': [5, 10],
    },
  };

  String _getClassDescription(String className) {
    final passive = HeroClasses.of(className);
    final flavor = switch (className) {
      'Warrior' =>
        "Masters of combat with high Strength and Vitality, but slower movement.",
      'Ranger' => "Balanced adventurers with good Speed and Luck.",
      'Mage' =>
        "Wielders of arcane power with high damage potential but low durability.",
      'Thief' => "Agile and lucky, excelling in Speed and avoiding danger.",
      _ => "",
    };
    return "$flavor\n★ ${passive.name}: ${passive.description}";
  }

  @override
  void initState() {
    super.initState();
    _generateName();
    _pickRandomPortrait();
  }

  void _pickRandomPortrait() {
    setState(() {
      _selectedPortrait = _portraits[Random().nextInt(_portraits.length)];
    });
  }

  void _generateName() {
    _nameController.text = TextGen.generateHeroName();
  }

  void _rollStats() {
    final random = Random();
    final stats = _classStats[_selectedClass]!;

    setState(() {
      _strength =
          stats['str']![0] +
          random.nextInt(stats['str']![1] - stats['str']![0] + 1);
      _speed =
          stats['spd']![0] +
          random.nextInt(stats['spd']![1] - stats['spd']![0] + 1);
      _hp =
          stats['hp']![0] +
          random.nextInt(stats['hp']![1] - stats['hp']![0] + 1);
      _luck =
          stats['luck']![0] +
          random.nextInt(stats['luck']![1] - stats['luck']![0] + 1);
      _statsRolled = true;
    });
  }

  void _createHero() {
    if (!_statsRolled) return;

    final newHero = HeroModel(
      id: const Uuid().v4(),
      name: _nameController.text,
      classType: _selectedClass,
      strength: _strength,
      speed: _speed,
      hp: _hp,
      maxHp: _hp,
      luck: _luck,
      level: 1,
      xp: 0,
      status: HeroStatus.idle,
      imagePath: _selectedPortrait,
    );

    ref.read(heroProvider.notifier).addHero(newHero);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("CREATE YOUR HERO", style: GoogleFonts.vt323(fontSize: 28)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portrait Selection (Square Retro Frame)
            Center(
              child: GestureDetector(
                onTap: _pickRandomPortrait,
                child: RetroPanel(
                  width: 140,
                  height: 140,
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFF0D0D0D),
                  borderWidth: 3,
                  bevelWidth: 3,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          _selectedPortrait,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 32,
                          height: 32,
                          color: Colors.amber,
                          child: const Icon(Icons.refresh, size: 18, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.pixelifySans(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      labelText: "HERO NAME",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RetroButton(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.amber,
                  onPressed: _generateName,
                  child: const Icon(FontAwesomeIcons.dice, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Class Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              dropdownColor: Colors.grey[900],
              style: GoogleFonts.pixelifySans(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                labelText: "CLASS",
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.toUpperCase(),
                          style: GoogleFonts.vt323(fontSize: 18),
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedClass = val!;
                _statsRolled = false; // Reset stats when class changes
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4),
              child: Text(
                _getClassDescription(_selectedClass).toUpperCase(),
                style: GoogleFonts.pixelifySans(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Header
            Text(
              "ATTRIBUTES",
              style: GoogleFonts.vt323(color: Colors.amber, fontSize: 24, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            
            // Attributes Panel
            RetroPanel(
              backgroundColor: const Color(0xFF0D0D0D),
              borderWidth: 2,
              bevelWidth: 2,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatRow("STRENGTH", _strength),
                  _buildStatRow("SPEED", _speed),
                  _buildStatRow("MAX HP", _hp),
                  _buildStatRow("LUCK", _luck),
                  const SizedBox(height: 16),
                  RetroButton(
                    backgroundColor: Colors.amber,
                    onPressed: _rollStats,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FontAwesomeIcons.diceD20, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          _statsRolled ? "RE-ROLL STATS" : "ROLL STATS",
                          style: GoogleFonts.vt323(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Button (Retro Style)
            RetroButton(
              backgroundColor: _statsRolled ? Colors.green[700] : Colors.grey[700],
              enabled: _statsRolled,
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: _createHero,
              child: Center(
                child: Text(
                  "BEGIN ADVENTURE",
                  style: GoogleFonts.vt323(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _statsRolled ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.pixelifySans(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            _statsRolled ? "$value" : "?",
            style: GoogleFonts.pixelifySans(
              color: _statsRolled ? Colors.white : Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
