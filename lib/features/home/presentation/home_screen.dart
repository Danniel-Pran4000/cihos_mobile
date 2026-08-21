import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/health_article.dart';
import 'widgets/article_card.dart';
import 'widgets/consultation_card.dart';
import 'widgets/home_header.dart';
import 'widgets/promo_carousel.dart';
import 'widgets/queue_monitor_card.dart';
import 'widgets/service_grid.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/widgets/pressable.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Which patient's consultations are shown. Null means everyone.
  String? _patientFilter;

  List<ServiceItem> _services(BuildContext context) => [
    ServiceItem(
      label: 'Video Call Dokter',
      icon: Icons.video_call_outlined,
      imageAsset: 'assets/images/videoCall.png',
      onTap: () => context.push(AppRoutes.videoCallSearch),
    ),
    ServiceItem(
      label: 'Dokter',
      icon: Icons.groups_2_outlined,
      imageAsset: 'assets/images/medicalTeam.png',
      onTap: () => context.push(AppRoutes.doctorFinder),
    ),
    ServiceItem(
      label: 'Janji Temu Dokter',
      icon: Icons.event_available_outlined,
      imageAsset: 'assets/images/medicalAppointment.png',
      onTap: () => context.push(AppRoutes.appointmentSearch),
    ),
    ServiceItem(
      label: 'Hasil Pemeriksaan',
      icon: Icons.description_outlined,
      imageAsset: 'assets/images/healthReport.png',
      onTap: () => context.push(AppRoutes.examResults),
    ),
    ServiceItem(
      label: 'Medical Check Up',
      icon: Icons.medical_services_outlined,
      imageAsset: 'assets/images/medical.png',
      onTap: () => context.push(AppRoutes.mcuPackages),
    ),
    ServiceItem(
      label: 'Promo',
      icon: Icons.local_offer_outlined,
      imageAsset: 'assets/images/sales.png',
      onTap: () => context.push(AppRoutes.promo),
    ),
  ];

  static final _articles = [
    HealthArticle(
      id: 'a1',
      title: 'Indonesia Running Series 2025 Berlangsung di 4 Kota!',
      date: DateTime(2025, 2, 23),
      imageAsset: 'assets/images/runner.png',
    ),
    HealthArticle(
      id: 'a2',
      title: 'Eating Clean, Cara Simpel Untuk Lebih Sehat',
      date: DateTime(2025, 2, 1),
      imageAsset: 'assets/images/eating-clean.jpg',
    ),
    HealthArticle(
      id: 'a3',
      title: '7 Manfaat Minum Teh Tawar, Si Pahit yang Kaya Nutrisi',
      date: DateTime(2025, 2, 1),
      imageAsset: 'assets/images/teh-tawar.jpg',
    ),
    HealthArticle(
      id: 'a4',
      title: 'Lokasi Jerawat Jadi Indikasi Masalah Kesehatan, Benarkah?',
      date: DateTime(2025, 2, 1),
      imageAsset: 'assets/images/jerawat.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final patientName = user?.fullName.toUpperCase() ?? 'NADILA';

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            children: [
              const HomeHeader(),
              const SizedBox(height: AppSpacing.md),
              const PromoCarousel(),
              const SizedBox(height: AppSpacing.xxl),
              ServiceGrid(items: _services(context)),
              const SizedBox(height: AppSpacing.xxl),
              QueueMonitorCard(
                onTap: () => context.push(AppRoutes.checkQueue),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Konsultasi Anda',
                    style: AppTypography.headingMd.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _PatientFilter(
                patientName: patientName,
                selected: _patientFilter,
                onChanged: (value) => setState(() => _patientFilter = value),
              ),
              const SizedBox(height: AppSpacing.md),
              ConsultationCard(
                patientName: patientName,
                scheduledAt: DateTime(2025, 2, 13, 12),
                endsAt: DateTime(2025, 2, 13, 12, 15),
                bookingCode: '0002367894',
                doctorName: 'dr. Edwin Hadinata, Sp.PD',
                specialty: 'Penyakit Dalam',
                hospital: 'Ciputra Hospital Surabaya',
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Info Kesehatan',
                        style: AppTypography.headingMd.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    key: const Key('moreArticles'),
                    onTap: () => context.push(AppRoutes.healthNews),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              for (final article in _articles) ...[
                Pressable(
                  scale: 0.98,
                  child: ArticleCard(
                    article: article,
                    onTap: () => context.push(AppRoutes.healthNews),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Semua" / per-patient chips above the consultation card.
class _PatientFilter extends StatelessWidget {
  const _PatientFilter({
    required this.patientName,
    required this.selected,
    required this.onChanged,
  });

  final String patientName;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'Semua',
          isSelected: selected == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: AppSpacing.md),
        _FilterChip(
          label: patientName,
          isSelected: selected == patientName,
          onTap: () => onChanged(patientName),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppElevation.level2,
      ),
      child: Material(
        color: isSelected ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
