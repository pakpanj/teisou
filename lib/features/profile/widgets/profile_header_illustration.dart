import 'package:flutter/material.dart';

/// Decorative torii-gate + Mt. Fuji + sun scene shown on the right side of
/// the Profile header card. Pure layered shapes/emoji (no image asset),
/// matching this app's existing "emoji + color placeholder" convention
/// (see AvatarPreset) rather than pulling in new artwork.
class ProfileHeaderIllustration extends StatelessWidget {
  const ProfileHeaderIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 170,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sun
            Positioned(
              top: 4,
              right: 10,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFBB6B9), Color(0xFFF4667A)],
                  ),
                ),
              ),
            ),
            // Mt. Fuji
            Positioned(
              bottom: 46,
              left: -10,
              right: -10,
              child: ClipPath(
                clipper: _MountainClipper(),
                child: Container(
                  height: 70,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFB9AEC7), Color(0xFF9C8FB0)],
                    ),
                  ),
                ),
              ),
            ),
            // Snow cap
            Positioned(
              bottom: 94,
              left: 32,
              child: ClipPath(
                clipper: _MountainClipper(),
                child: Container(
                  width: 66,
                  height: 22,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            // Water / ground line
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 46,
                color: const Color(0xFFF6D9DD).withValues(alpha: 0.6),
              ),
            ),
            // Torii gate
            Positioned(
              bottom: 4,
              left: 40,
              child: _ToriiGate(),
            ),
            // Sakura blossoms
            const Positioned(top: 2, right: 0, child: _Blossom(size: 16)),
            const Positioned(top: 30, right: 4, child: _Blossom(size: 12)),
            const Positioned(top: 16, right: 26, child: _Blossom(size: 10)),
          ],
        ),
      ),
    );
  }
}

class _ToriiGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE0637A);
    return SizedBox(
      width: 50,
      height: 46,
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Container(height: 6, color: color),
          ),
          Positioned(
            top: 12,
            left: 4,
            right: 4,
            child: Container(height: 4, color: color),
          ),
          Positioned(
            top: 4,
            bottom: 0,
            left: 6,
            child: Container(width: 6, color: color),
          ),
          Positioned(
            top: 4,
            bottom: 0,
            right: 6,
            child: Container(width: 6, color: color),
          ),
        ],
      ),
    );
  }
}

class _Blossom extends StatelessWidget {
  final double size;

  const _Blossom({required this.size});

  @override
  Widget build(BuildContext context) {
    return Text('🌸', style: TextStyle(fontSize: size));
  }
}

class _MountainClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.5 + size.width * 0.14, size.height * 0.35);
    path.lineTo(size.width * 0.78, size.height * 0.35);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.22, size.height * 0.35);
    path.lineTo(size.width * 0.5 - size.width * 0.14, size.height * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
