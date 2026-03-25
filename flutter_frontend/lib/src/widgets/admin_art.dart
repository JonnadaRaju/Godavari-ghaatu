import 'dart:math' as math;

import 'package:flutter/material.dart';

class AdminHeroStat {
  const AdminHeroStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;
}

class AdminHeroBanner extends StatelessWidget {
  const AdminHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.stats,
    this.accent = const Color(0xFFB45309),
    this.action,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final List<AdminHeroStat> stats;
  final Color accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: CustomPaint(
        painter: _AdminHeroPainter(accent: accent),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1F2937),
                accent.withOpacity(0.94),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: Text(
                  eyebrow.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFFFE7CD), height: 1.45, fontSize: 15),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map(
                      (stat) => _StatCard(
                        label: stat.label,
                        value: stat.value,
                        color: stat.color ?? Colors.white,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComboBlueprintCard extends StatelessWidget {
  const ComboBlueprintCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: const _BlueprintPainter(),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF9F7F2), Color(0xFFFFFBF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFE3D8C8)),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2C231C),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6B5C4E), height: 1.45),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class SectionAccentLabel extends StatelessWidget {
  const SectionAccentLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        color: Color(0xFF9A3412),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFFFE7CD), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AdminHeroPainter extends CustomPainter {
  const _AdminHeroPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.84, size.height * 0.2), radius: size.width * 0.34));
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.2), size.width * 0.34, haloPaint);

    final ribbon = Path()
      ..moveTo(size.width * 0.52, -20)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.08, size.width * 0.96, size.height * 0.34)
      ..lineTo(size.width, size.height * 0.56)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()..color = accent.withOpacity(0.28),
    );

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.12, size.height * 0.8), radius: size.width * 0.24),
      math.pi * 1.2,
      math.pi * 1.2,
      false,
      orbitPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.12, size.height * 0.8), radius: size.width * 0.3),
      math.pi * 1.35,
      math.pi,
      false,
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AdminHeroPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8DFD2)
      ..strokeWidth = 1;

    for (double x = 24; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 24; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB45309).withOpacity(0.16);

    final path = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.52, size.width * 0.54, size.height * 0.72)
      ..quadraticBezierTo(size.width * 0.74, size.height * 0.88, size.width, size.height * 0.64);
    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
