import 'package:flutter/material.dart';

class WellbeingSection extends StatelessWidget {
  const WellbeingSection({
    super.key,
    required this.total,
    required this.urgent,
    required this.weeklyDeltaPercent,
    required this.isDark,
  });

  final int total;
  final int urgent;
  final int weeklyDeltaPercent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panel = const Color(0xFF0F4D52);
    final surface = isDark ? const Color(0xFF23262A) : Colors.white;
    final softText = isDark ? const Color(0xFFB8C0C2) : const Color(0xFF7B8086);
    final mainText = isDark ? const Color(0xFFEAF0F1) : const Color(0xFF202326);
    final accent = const Color(0xFFF4AD2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Digital Wellbeing',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: mainText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'swipe up to return',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Digital\nWellbeing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final day = ['M', 'T', 'W', 'T', 'F'][index];
                  final num = (index + 1).toString();
                  final selected = index == 4;
                  return Column(
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: selected ? accent : Colors.transparent,
                        child: Text(
                          num,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Saturday, April 5th',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: mainText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Load · 7 days',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _BarColumn(
                    label: 'EMG',
                    height: 32,
                    color: Color(0xFFF2DFDF),
                  ),
                  _BarColumn(
                    label: 'HIGH',
                    height: 54,
                    color: Color(0xFFF4AD2B),
                  ),
                  _BarColumn(
                    label: 'MED',
                    height: 68,
                    color: Color(0xFF8DB8B8),
                  ),
                  _BarColumn(
                    label: 'LOW',
                    height: 76,
                    color: Color(0xFF5A8C89),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: '$total',
                subtitle: 'Total',
                titleColor: panel,
                background: surface,
                subtitleColor: softText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: '$weeklyDeltaPercent%',
                subtitle: 'vs last week',
                titleColor: const Color(0xFFE08C00),
                background: surface,
                subtitleColor: softText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                title: '$urgent',
                subtitle: 'Urgent',
                titleColor: const Color(0xFFBD3124),
                background: surface,
                subtitleColor: softText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3D331E) : const Color(0xFFF2E8CF),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accent, width: 5)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Text(
            'AI Insight\nYou saved 2.1 hrs this week by reducing low-priority checks.',
            style: TextStyle(
              color: isDark ? const Color(0xFFF5DB9A) : const Color(0xFF8A5A10),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.height,
    required this.color,
  });

  final String label;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.background,
    required this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final Color titleColor;
  final Color background;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
