import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/game_provider.dart';
import '../widgets/business_selection_view.dart';
import '../widgets/business_dashboard_view.dart';

class HallScreen extends ConsumerWidget {
  const HallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final activeBusiness = gameState.activeBusiness;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          'THE HALL',
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
      body: activeBusiness == null
          ? const BusinessSelectionView()
          : BusinessDashboardView(business: activeBusiness),
    );
  }
}
