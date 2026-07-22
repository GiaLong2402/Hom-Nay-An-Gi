import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/home_shell.dart';

/// Màn giới thiệu khi mở app — bấm nút để vào Home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _buttonFade;

  bool _entering = false;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.28, 0.72, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.28, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
      ),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.7, 1, curve: Curves.easeOut),
      ),
    );

    _enterController.forward();
  }

  void _goHome() {
    if (_entering) return;
    setState(() => _entering = true);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 480),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => const HomeShell(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF1A120C),
                    Color(0xFF2A1810),
                    Color(0xFF3D2214),
                  ]
                : const [
                    Color(0xFFFFF4EB),
                    Color(0xFFFFE0C7),
                    Color(0xFFFFC48A),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Column(
              children: [
                const Spacer(),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.seed,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.seed.withValues(alpha: 0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      'Hôm Nay Ăn Gì?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: isDark ? Colors.white : const Color(0xFF2B1A10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Quyết định món ăn chỉ trong vài giây',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.72)
                          : const Color(0xFF6B4A35),
                    ),
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: _buttonFade,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _entering ? null : _goHome,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.seed,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('Cùng ăn thôi!'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
