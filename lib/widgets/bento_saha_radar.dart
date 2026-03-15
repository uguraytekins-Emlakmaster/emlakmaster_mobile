import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emlakmaster_mobile/core/services/firestore_service.dart';
import 'package:flutter/material.dart';

/// Diyarbakır ilçe adlarına göre sembolik harita üzerinde x,y oranları (0-1).
final Map<String, Offset> _districtPositions = {
  'Bağlar': const Offset(0.25, 0.55),
  'Kayapınar': const Offset(0.72, 0.35),
  'Sur': const Offset(0.5, 0.5),
  'Yenişehir': const Offset(0.45, 0.28),
  'Bismil': const Offset(0.82, 0.75),
  'Çınar': const Offset(0.35, 0.82),
  'Ergani': const Offset(0.18, 0.35),
  'Silvan': const Offset(0.65, 0.62),
  'Kocaköy': const Offset(0.15, 0.5),
  'Çüngüş': const Offset(0.22, 0.88),
};

class BentoSahaRadar extends StatelessWidget {
  const BentoSahaRadar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.agentsStream(),
      builder: (context, snapshot) {
        final agents = snapshot.hasData ? snapshot.data!.docs : <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final withLocation = agents
            .where((d) {
              final data = d.data();
              final city = data['locationCity'] as String?;
              final district = data['locationDistrict'] as String?;
              return (city != null && city.isNotEmpty) || (district != null && district.isNotEmpty);
            })
            .toList();
        final subtitle = snapshot.hasData
            ? '${withLocation.length} danışman harita üzerinde'
            : 'Yükleniyor...';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.04),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saha-Radar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: const Color(0xFF161B22),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: snapshot.hasData
                        ? CustomPaint(
                            painter: DiyarbakirMapPainter(agents: withLocation),
                            size: Size.infinite,
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DiyarbakirMapPainter extends CustomPainter {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> agents;

  DiyarbakirMapPainter({required this.agents});

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 12.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    const left = padding;
    const top = padding;

    // Sembolik Diyarbakır sınırı (yuvarlatılmış dikdörtgen + Dicle kıvrımı)
    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, w, h),
        const Radius.circular(20),
      ));
    canvas.drawPath(
      borderPath,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // İlçe isimleri için nokta pozisyonları; konumu olan danışmanları yeşil nokta yap
    const dotRadius = 6.0;
    final greenPaint = Paint()
      ..color = const Color(0xFF00FF41)
      ..style = PaintingStyle.fill;
    final greenStroke = Paint()
      ..color = const Color(0xFF00FF41).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final doc in agents) {
      final data = doc.data();
      final district = (data['locationDistrict'] as String?)?.trim();
      final city = (data['locationCity'] as String?)?.trim();
      if ((district == null || district.isEmpty) && (city == null || city.isEmpty)) continue;

      final key = (district != null && district.isNotEmpty)
          ? district
          : (city ?? '');
      Offset? pos = _districtPositions[key];
      if (pos == null && key.isNotEmpty) {
        pos = _districtPositions.isNotEmpty
            ? _districtPositions.values.first
            : const Offset(0.5, 0.5);
      }
      if (pos == null) continue;

      final dx = left + w * pos.dx;
      final dy = top + h * pos.dy;
      canvas.drawCircle(Offset(dx, dy), dotRadius, greenStroke);
      canvas.drawCircle(Offset(dx, dy), dotRadius - 1, greenPaint);
    }

    // "Diyarbakır" etiketi
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Diyarbakır',
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(left + w - textPainter.width - 8, top + h - textPainter.height - 6),
    );
  }

  @override
  bool shouldRepaint(covariant DiyarbakirMapPainter oldDelegate) {
    return oldDelegate.agents != agents;
  }
}
