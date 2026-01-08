import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  final int eraIndex;

  const HistoryScreen({super.key, required this.eraIndex});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scrollAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Slow scroll
    );

    _scrollAnimation = Tween<double>(begin: 1.0, end: -1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.linear),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      // Navigate to Home after animation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _historyText {
    switch (widget.eraIndex) {
      case 1: // Warrior -> Thief
        return "The Empire you built brought peace, but peace breeds corruption.\n\n"
            "In the shadows of your great monuments, a new guild rises.\n\n"
            "Thieves, spies, and assassins now rule the night.\n\n"
            "The Age of Steel has ended.\n"
            "The Age of Shadows begins.";
      case 2: // Thief -> Mage
        return "The Empire collapsed from within. The chaos has torn the veil of reality.\n\n"
            "Magic floods the ruins of the old world.\n\n"
            "Wizards and sorcerers claim the remnants of power.\n\n"
            "The Age of Shadows has burned away.\n"
            "The Age of Arcana begins.";
      default: // Mage -> Warrior (Loop)
        return "The magic consumed itself, leaving only dust and echoes.\n\n"
            "From the ashes, strong men rise to rebuild.\n\n"
            "The cycle turns once more.\n\n"
            "The Age of Arcana fades.\n"
            "The Age of Steel returns.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: Center(
          child: AnimatedBuilder(
            animation: _scrollAnimation,
            builder: (context, child) {
              final height = MediaQuery.of(context).size.height;
              return Transform.translate(
                offset: Offset(0, _scrollAnimation.value * height * 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    _historyText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
