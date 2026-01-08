import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../widgets/business_selection_view.dart';
import '../widgets/business_dashboard_view.dart';

class HallScreen extends ConsumerWidget {
  const HallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final activeBusiness = gameState.activeBusiness;

    return Container(
      color: const Color(0xFF1A1A1A),
      child: activeBusiness == null
          ? const BusinessSelectionView()
          : BusinessDashboardView(business: activeBusiness),
    );
  }
}
