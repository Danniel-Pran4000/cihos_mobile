import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/hospital_logo.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notifications/application/notifications_controller.dart';

/// Logo, notification bell, emergency shortcut (IGD), and greeting.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final unread = ref.watch(unreadNotificationCountProvider);
    final firstName = user?.fullName.split(' ').first ?? 'Pengguna';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Logo (Left) aligned with Notification Bell & IGD (Right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const HospitalLogo.small(),
            const Spacer(),
            _BellButton(
              unread: unread,
              onTap: () => context.push(AppRoutes.notifications),
            ),
            const SizedBox(width: 8),
            const _EmergencyChip(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Welcome Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, $firstName!',
              style: AppTypography.headingMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bagaimana kondisi kesehatan Anda hari ini?',
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.danger,
              smallSize: 8,
              child: const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.accentSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyChip extends StatelessWidget {
  const _EmergencyChip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFDEDE),
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push(AppRoutes.emergency),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDEDE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AmbulanceIcon(
                size: 19,
                color: Color(0xFFE74949),
              ),
              SizedBox(width: 6),
              Text(
                'IGD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE74949),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom vector ambulance icon matching the exact Figma design.
class _AmbulanceIcon extends StatelessWidget {
  const _AmbulanceIcon({this.size = 20, this.color = const Color(0xFFE74949)});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.28, size),
      painter: _AmbulancePainter(color: color),
    );
  }
}

class _AmbulancePainter extends CustomPainter {
  const _AmbulancePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Body of the ambulance (left box + cabin)
    final bodyPath = Path();

    // Main box body on left
    final vanRRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, h * 0.12, w * 0.65, h * 0.66),
      topLeft: Radius.circular(w * 0.08),
      bottomLeft: Radius.circular(w * 0.04),
    );
    bodyPath.addRRect(vanRRect);

    // Front cabin on right
    final cabinPath = Path()
      ..moveTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.74, h * 0.30)
      ..lineTo(w * 0.94, h * 0.52)
      ..arcToPoint(
        Offset(w * 0.98, h * 0.60),
        radius: Radius.circular(w * 0.05),
      )
      ..lineTo(w * 0.98, h * 0.78)
      ..lineTo(w * 0.60, h * 0.78)
      ..close();
    bodyPath.addPath(cabinPath, Offset.zero);

    canvas.drawPath(bodyPath, paint);

    // Windshield window (white cutout)
    final windowPath = Path()
      ..moveTo(w * 0.66, h * 0.36)
      ..lineTo(w * 0.73, h * 0.36)
      ..lineTo(w * 0.88, h * 0.53)
      ..lineTo(w * 0.66, h * 0.53)
      ..close();
    canvas.drawPath(windowPath, whitePaint);

    // Cross in the center of the van (white)
    final crossCenterX = w * 0.325;
    final crossCenterY = h * 0.45;
    final crossSize = h * 0.34;
    final crossThickness = crossSize * 0.38;

    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(crossCenterX, crossCenterY),
          width: crossSize,
          height: crossThickness,
        ),
        Radius.circular(crossThickness * 0.15),
      ),
      whitePaint,
    );

    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(crossCenterX, crossCenterY),
          width: crossThickness,
          height: crossSize,
        ),
        Radius.circular(crossThickness * 0.15),
      ),
      whitePaint,
    );

    // Wheels (red with white center)
    final wheelRadius = h * 0.16;
    final rearWheelCenter = Offset(w * 0.22, h * 0.82);
    final frontWheelCenter = Offset(w * 0.78, h * 0.82);

    canvas.drawCircle(rearWheelCenter, wheelRadius, paint);
    canvas.drawCircle(frontWheelCenter, wheelRadius, paint);

    canvas.drawCircle(rearWheelCenter, wheelRadius * 0.4, whitePaint);
    canvas.drawCircle(frontWheelCenter, wheelRadius * 0.4, whitePaint);
  }

  @override
  bool shouldRepaint(covariant _AmbulancePainter oldDelegate) =>
      oldDelegate.color != color;
}
