import 'package:flutter/material.dart';

class PriorityCard extends StatelessWidget {
  const PriorityCard({
    super.key,
    required this.label,
    required this.count,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.isLarge,
    required this.onTap,
  });

  final String label;
  final int count;
  final String subtitle;
  final Color background;
  final Color foreground;
  final bool isLarge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(isLarge ? 18 : 14),
        height: isLarge ? 170 : 120,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                color: foreground,
                fontSize: isLarge ? 40 : 32,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            const Spacer(),
            Text(
              subtitle,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
