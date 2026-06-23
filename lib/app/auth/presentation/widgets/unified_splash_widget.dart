import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app_admin/core/colors/app_colors.dart';

class UnifiedSplashWidget extends StatelessWidget {
  const UnifiedSplashWidget({
    super.key,
    this.showLoadingIndicator = true,
    this.logoAnimation,
  });

  final bool showLoadingIndicator;
  final Animation<double>? logoAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget logo = Image.asset(
      'assets/icons/iconapp.png',
      width: 130,
      height: 130,
      fit: BoxFit.contain,
    );

    if (logoAnimation != null) {
      logo = ScaleTransition(
        scale: logoAnimation!,
        child: FadeTransition(
          opacity: logoAnimation!,
          child: logo,
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF08101C),
                    Color(0xFF0D1726),
                    Color(0xFF101B2D),
                  ]
                : const [
                    Color(0xFFF5F7FB),
                    Color(0xFFEEF3FA),
                    Color(0xFFEAF1FF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -120,
              left: -40,
              child: _BackgroundOrb(size: 320, color: Color(0x552563EB)),
            ),
            const Positioned(
              right: -80,
              top: 120,
              child: _BackgroundOrb(size: 280, color: Color(0x3C0EA5E9)),
            ),
            const Positioned(
              left: 120,
              bottom: -120,
              child: _BackgroundOrb(size: 260, color: Color(0x2816A34A)),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  logo,
                  const SizedBox(height: 24),
                  Text(
                    'TOLAB',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'وصول جامعي موحّد',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (showLoadingIndicator) ...[
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 140,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 56, sigmaY: 56),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
