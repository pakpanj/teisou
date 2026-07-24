import 'package:flutter/material.dart';

/// Decorative "cat napping under a sakura tree" scene shown when the user
/// has no exam history yet. Layered shapes/emoji, same convention as
/// [ProfileHeaderIllustration] — no image asset.
class ExamHistoryEmptyIllustration extends StatelessWidget {
  const ExamHistoryEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 80,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Trunk
          Positioned(
            bottom: 0,
            left: 40,
            child: Container(
              width: 8,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFB08968),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Canopy (clustered blossom circles)
          const Positioned(top: 0, left: 14, child: _Canopy(size: 34)),
          const Positioned(top: 10, left: 40, child: _Canopy(size: 38)),
          const Positioned(top: 4, left: 54, child: _Canopy(size: 30)),
          // Napping cat
          const Positioned(bottom: 2, left: 4, child: Text('😴', style: TextStyle(fontSize: 20))),
          const Positioned(
            bottom: 0,
            left: 0,
            child: Text('🐱', style: TextStyle(fontSize: 30)),
          ),
        ],
      ),
    );
  }
}

class _Canopy extends StatelessWidget {
  final double size;

  const _Canopy({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBD3D9), Color(0xFFF6B8C1)],
        ),
      ),
    );
  }
}
