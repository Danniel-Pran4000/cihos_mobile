import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/registration_illustration.dart';

/// The dark rounded card holding an auth form, with the illustration seated on
/// its top edge.
///
/// The artwork overlaps rather than floating clear of the card — its feet sit
/// just inside the rounded corner — so the two read as one piece.
class AuthCard extends StatefulWidget {
  const AuthCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.illustrationWidth = 200,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double illustrationWidth;

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    // A gentle overshoot so the card settles rather than snapping.
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How far the artwork sinks into the card, hiding the feet behind its edge.
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    final illustrationHeight =
        widget.illustrationWidth / RegistrationIllustration.aspectRatio;

    return ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1.0).animate(_curve),
      child: FadeTransition(
        opacity: _controller,
        child: Padding(
        // Leaves room for the part of the artwork above the card.
        padding: EdgeInsets.only(top: illustrationHeight - _overlap),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            _CardBody(
              title: widget.title,
              subtitle: widget.subtitle,
              topPadding: _overlap + AppSpacing.lg,
              children: widget.children,
            ),
            Positioned(
              top: -(illustrationHeight - _overlap),
              child: RegistrationIllustration(width: widget.illustrationWidth),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.title,
    required this.subtitle,
    required this.topPadding,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final double topPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.cardH),
      padding: EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        top: topPadding,
        bottom: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headingMd,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTypography.fieldLabel.copyWith(
                color: AppColors.onAccentMuted,
                fontSize: 15,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          ...children,
        ],
      ),
    );
  }
}
