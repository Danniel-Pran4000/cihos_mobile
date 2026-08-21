import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/illustrations.dart';
import '../../../core/widgets/textured_background.dart';
import '../../auth/application/auth_controller.dart';
import '../data/history_repository.dart';
import '../domain/past_appointment.dart';
import '../../../core/theme/app_elevation.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/staggered_entrance.dart';

/// "Riwayat Jadwal Temu" — finished visits with search & calendar date filter.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    final visits = ref.watch(pastAppointmentsProvider);
    final user = ref.watch(authControllerProvider).user;
    final photoUrl = user?.photoUrl;

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID')
        .format(DateTime.now())
        .toUpperCase();

    // Filter by search query and date
    final filteredVisits = visits.where((v) {
      final matchesQuery = _query.isEmpty ||
          v.doctorName.toLowerCase().contains(_query.toLowerCase()) ||
          v.specialty.toLowerCase().contains(_query.toLowerCase()) ||
          v.patientName.toLowerCase().contains(_query.toLowerCase());

      final matchesDate = _selectedDate == null ||
          (v.startsAt.year == _selectedDate!.year &&
              v.startsAt.month == _selectedDate!.month &&
              v.startsAt.day == _selectedDate!.day);

      return matchesQuery && matchesDate;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(current: AppTab.history),
      body: TexturedBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section (Eyebrow date, Title 'Riwayat', and User Avatar)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayFormatted,
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Riwayat',
                          style: AppTypography.headingLg.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        // Profile Avatar thumbnail
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border:
                                Border.all(color: AppColors.border, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildAvatar(photoUrl),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val.trim()),
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama dokter atau spesialis...',
                      hintStyle: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Date/Month Filter Row with Calendar Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Semua Riwayat'
                                : DateFormat('d MMMM yyyy', 'id_ID')
                                    .format(_selectedDate!),
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_selectedDate != null)
                            InkWell(
                              onTap: _clearDateFilter,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.border,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pilih Tanggal Kalender',
                      icon: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Visits List
              Expanded(
                child: filteredVisits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Illustrations.emptySchedule(size: 140),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _query.isNotEmpty || _selectedDate != null
                                  ? 'Tidak ada riwayat yang sesuai'
                                  : 'Belum ada riwayat kunjungan',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentSoft,
                              ),
                            ),
                            if (_query.isNotEmpty || _selectedDate != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.sm),
                                child: TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _query = '';
                                      _selectedDate = null;
                                    });
                                  },
                                  child: const Text('Reset Filter'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.sm,
                          AppSpacing.xxl,
                          AppSpacing.xxxl,
                        ),
                        itemCount: filteredVisits.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (context, index) => StaggeredEntrance(
                          index: index,
                          child: Pressable(
                            scale: 0.98,
                            child: _VisitCard(visit: filteredVisits[index]),
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

  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      } else if (photoUrl.startsWith('http')) {
        return Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.person,
            size: 22,
            color: AppColors.textTertiary,
          ),
        );
      }
    }
    return Image.asset(
      'assets/images/avatar.jpg',
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.person,
        size: 22,
        color: AppColors.textTertiary,
      ),
    );
  }
}

/// One finished visit: doctor, when it happened, and a rebook shortcut.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});

  final PastAppointment visit;

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(visit.startsAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppElevation.level2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.kind.label,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                _OutcomeChip(outcome: visit.outcome),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  visit.kind == VisitKind.videoCall
                      ? Icons.videocam
                      : Icons.person,
                  size: 23,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.doctorName,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSoft,
                        ),
                      ),
                      Text(
                        visit.specialty,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              date,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accentSoft,
              ),
            ),
            Text(
              visit.timeRange,
              style: AppTypography.bodySm.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.patientName,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentSoft,
                    ),
                  ),
                ),
                _RebookButton(visit: visit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Selesai" / "Dibatalkan" badge in the card's top-right corner.
class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome});

  final VisitOutcome outcome;

  @override
  Widget build(BuildContext context) {
    // Status carries meaning, so it carries colour: a cancelled visit should
    // not look identical to a completed one at a glance.
    final (background, foreground) = switch (outcome) {
      VisitOutcome.completed => (
        AppColors.successSurface,
        AppColors.success,
      ),
      VisitOutcome.cancelled => (AppColors.dangerSurface, AppColors.danger),
      VisitOutcome.missed => (AppColors.warningSurface, AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        outcome.label,
        style: AppTypography.bodySm.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Drops the user back into the booking flow, pre-set to the same kind.
class _RebookButton extends StatelessWidget {
  const _RebookButton({required this.visit});

  final PastAppointment visit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        key: Key('rebook_${visit.id}'),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        // Each search route carries its own kind, so the path is the choice.
        onTap: () => context.push(
          visit.kind == VisitKind.videoCall
              ? AppRoutes.videoCallSearch
              : AppRoutes.appointmentSearch,
        ),
        child: Container(
          height: 21,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Buat Janji Ulang',
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.lavender,
            ),
          ),
        ),
      ),
    );
  }
}
