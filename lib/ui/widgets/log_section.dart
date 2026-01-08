import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/log_provider.dart';
import '../../models/log_entry_model.dart';
import 'package:intl/intl.dart';

class LogSection extends ConsumerWidget {
  const LogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logProvider);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black],
            stops: [0.0, 0.1, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          reverse: true, // Newest at bottom
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.lato(fontSize: 14),
                  children: [
                    TextSpan(
                      text: "[${DateFormat('HH:mm:ss').format(log.timestamp)}] ",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextSpan(
                      text: log.message,
                      style: TextStyle(color: _getColorForLogType(log.type)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getColorForLogType(LogType type) {
    switch (type) {
      case LogType.info:
        return Colors.white;
      case LogType.combat:
        return Colors.redAccent;
      case LogType.loot:
        return Colors.greenAccent;
      case LogType.gold:
        return Colors.amber;
    }
  }
}
