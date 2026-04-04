import 'dart:math' as math;

import 'package:flutter/material.dart';

class AiOrbFab extends StatefulWidget {
  const AiOrbFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AiOrbFab> createState() => _AiOrbFabState();
}

class _AiOrbFabState extends State<AiOrbFab> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 78,
        height: 78,
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _waveController]),
          builder: (context, child) {
            final t = _rotationController.value;
            final wave = _waveController.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                _WaveRing(
                  progress: wave,
                  baseSize: 64,
                  color: const Color(0xFF6C5CFF),
                ),
                _WaveRing(
                  progress: (wave + 0.33) % 1,
                  baseSize: 64,
                  color: const Color(0xFF27C8F6),
                ),
                _WaveRing(
                  progress: (wave + 0.66) % 1,
                  baseSize: 64,
                  color: const Color(0xFFCF66FF),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A3FFC).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.25, -0.3),
                      radius: 0.95,
                      colors: [
                        isDark
                            ? const Color(0xFFB8EDFF)
                            : const Color(0xFFD4F5FF),
                        const Color(0xFF0CB4E8),
                        const Color(0xFF3E36F6),
                        const Color(0xFFAF4CF4),
                      ],
                      stops: const [0.08, 0.42, 0.75, 1],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.42),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.18, 0.42, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -t * 2 * math.pi * 0.6,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: t * 2 * math.pi * 0.8,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.85),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WaveRing extends StatelessWidget {
  const _WaveRing({
    required this.progress,
    required this.baseSize,
    required this.color,
  });

  final double progress;
  final double baseSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = 1 + (progress * 0.9);
    final opacity = (1 - progress) * 0.35;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: opacity), width: 2),
        ),
      ),
    );
  }
}
