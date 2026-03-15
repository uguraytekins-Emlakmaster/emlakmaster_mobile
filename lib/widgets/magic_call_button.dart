import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MagicCallButton extends StatelessWidget {
  final VoidCallback onTap;

  const MagicCallButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.mediumImpact(),
      onTap: onTap,
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF00FF41),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_in_talk_rounded, color: Colors.black, size: 22),
            SizedBox(width: 10),
            Text(
              'Magic Call & AI Wizard',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
