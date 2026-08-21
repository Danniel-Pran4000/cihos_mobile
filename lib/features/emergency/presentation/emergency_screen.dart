import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/textured_background.dart';

/// Emergency department contact screen.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const _phone = '031-21021911';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: TexturedBackground(
        child: Stack(
          children: [
            // Image positioned safely below the back button area, extending downwards
            Positioned(
              top: topPadding + 92,
              left: 0,
              right: 0,
              height: screenHeight * 0.50,
              child: Image.asset(
                'assets/images/emergency_hero.jpg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(
                      Icons.local_hospital_outlined,
                      size: 64,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Gawat Darurat Dark Blue Panel with extended height to clearly overlap and cover the bottom of the image
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.38,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      offset: Offset(0, -6),
                      blurRadius: 24,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Gawat Darurat',
                        textAlign: TextAlign.center,
                        style: AppTypography.headingLg.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Dapatkan bantuan gawat darurat medis dari Ciputra Hospital Surabaya',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _CallCard(phone: _phone),
                    ],
                  ),
                ),
              ),
            ),

            // Standard Dark Back Button sitting cleanly at top in clear area
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child: AppBackButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            offset: Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () async {
            await Clipboard.setData(const ClipboardData(text: '03121021911'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nomor IGD 031-21021911 disalin ke papan klip.'),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hubungi Kami Segera',
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.emergency_rounded,
                            size: 24,
                            color: Color(0xFFE74949),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                phone,
                                style: AppTypography.headingLg.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFEEEE),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_rounded,
                    size: 26,
                    color: Color(0xFFE74949),
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
