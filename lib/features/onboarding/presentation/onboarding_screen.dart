import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hospital_logo.dart';
import '../../../core/widgets/registration_illustration.dart';
import '../../../core/widgets/textured_background.dart';

/// Welcome screen between the splash and sign-in: what the app is for, then a
/// way in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fades a child in, sliding it up, staggered by [order].
  Widget _entrance({required int order, required Widget child}) {
    final start = (order * 0.12).clamp(0.0, 0.7);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.xxl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _entrance(order: 0, child: const HospitalLogo.splash()),
                        _entrance(
                          order: 1,
                          // Bounded by height as well as width: on short
                          // screens the artwork must yield to the headline and
                          // the actions below it.
                          child: RegistrationIllustration(
                            width: [
                              MediaQuery.sizeOf(context).width * 0.62,
                              constraints.maxHeight * 0.30,
                              280.0,
                            ].reduce((a, b) => a < b ? a : b),
                          ),
                        ),
                        Column(
                          children: [
                            _entrance(
                              order: 2,
                              child: Text(
                                'Kesehatan Anda,\ndalam genggaman',
                                textAlign: TextAlign.center,
                                style: AppTypography.headingLg,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _entrance(
                              order: 3,
                              child: Text(
                                'Atur janji temu, lihat rekam medis, dan '
                                'konsultasi dengan dokter Ciputra Hospital '
                                'Surabaya — semua dari satu aplikasi.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            _entrance(
                              order: 4,
                              child: AppButton(
                                label: 'Mulai',
                                expand: true,
                                onPressed: () => context.go(AppRoutes.login),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _entrance(
                              order: 5,
                              child: TextButton(
                                key: const Key('onboardingRegister'),
                                onPressed: () => context.go(AppRoutes.register),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Pasien baru? '),
                                      TextSpan(
                                        text: 'Daftar di sini',
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          ),
        ),
      ),
    );
  }
}
