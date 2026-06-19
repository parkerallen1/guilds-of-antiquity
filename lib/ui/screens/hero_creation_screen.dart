import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../providers/hero_provider.dart';
import '../../models/hero_model.dart';
import '../../utils/text_gen.dart';

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
    switch (className) {
      case 'Warrior':
        return "Masters of combat with high Strength and Vitality, but slower movement.";
      case 'Ranger':
        return "Balanced adventurers with good Speed and Luck.";
      case 'Mage':
        return "Wielders of arcane power with high damage potential but low durability.";
      case 'Thief':
        return "Agile and lucky, excelling in Speed and avoiding danger.";
      default:
        return "";
    }
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
      backgroundColor: const Color(0xFF222222),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Create Your Hero", style: GoogleFonts.cinzel()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Portrait Selection
            Center(
              child: GestureDetector(
                onTap: _pickRandomPortrait,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage(_selectedPortrait),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.refresh, size: 16, color: Colors.black),
                    ),
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
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Hero Name",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.dice, color: Colors.amber),
                  onPressed: _generateName,
                  tooltip: "Random Name",
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Class Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedClass,
              dropdownColor: Colors.grey[850],
              style: GoogleFonts.cinzel(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Class",
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedClass = val!;
                _statsRolled = false; // Reset stats when class changes
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 4),
              child: Text(
                _getClassDescription(_selectedClass),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Text(
              "Attributes",
              style: GoogleFonts.cinzel(color: Colors.amber, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                children: [
                  _buildStatRow("Strength", _strength),
                  _buildStatRow("Speed", _speed),
                  _buildStatRow("Max HP", _hp),
                  _buildStatRow("Luck", _luck),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _rollStats,
                    icon: const Icon(FontAwesomeIcons.diceD20),
                    label: Text(_statsRolled ? "Re-Roll Stats" : "Roll Stats"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _statsRolled ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _statsRolled ? _createHero : null,
              child: Text(
                "BEGIN ADVENTURE",
                style: GoogleFonts.cinzel(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            _statsRolled ? "$value" : "?",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
