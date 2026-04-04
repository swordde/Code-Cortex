import 'package:flutter/material.dart';

class QuickFilterDot extends StatelessWidget {
  const QuickFilterDot({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark
          ? const Color(0xFF2A2D30)
          : const Color(0xFFF0F0F0),
      child: Icon(
        icon,
        size: 16,
        color: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF2C2C2C),
      ),
    );
  }
}
