import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/pg_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2100), _leave);
  }

  void _leave() {
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _leave,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.1,
              colors: [Color(0xFF16302B), Color(0xFF0A1210)],
              stops: [0, 0.62],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.9,
                      colors: [
                        const Color(0xFFE8B36B).withOpacity(.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF5BC2B3).withOpacity(.22),
                            const Color(0xFFE8B36B).withOpacity(.14),
                          ],
                        ),
                        border: Border.all(color: Colors.white.withOpacity(.12)),
                      ),
                      child: const Icon(Icons.self_improvement_rounded, size: 46, color: Color(0xFF5BC2B3)),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Prayer Guide',
                      style: PgText.serif(size: 30, weight: FontWeight.w600, color: const Color(0xFFECEAE3)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BE STILL & KNOW',
                      style: PgText.sans(
                        size: 13,
                        letterSpacing: 2,
                        weight: FontWeight.w500,
                        color: const Color(0xFF5E6D69),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 64,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5BC2B3),
                      backgroundColor: Color(0x24FFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
