import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class FaqSheet extends StatelessWidget {
  const FaqSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FaqSheet(),
    );
  }

  static const _faqs = [
    (
      q: 'Bagaimana cara membuat janji temu dokter?',
      a: 'Pilih menu "Janji Temu" di beranda, cari dokter atau spesialis yang diinginkan, pilih tanggal & jam praktek, lengkapi data pasien, lalu konfirmasi jadwal Anda.',
    ),
    (
      q: 'Apakah pendaftaran pasien baru bisa online?',
      a: 'Ya, Anda dapat mendaftarkan diri atau anggota keluarga langsung melalui aplikasi dengan mengisi nomor NIK dan data diri yang sesuai KTP.',
    ),
    (
      q: 'Bagaimana cara menggunakan asuransi/BPJS?',
      a: 'Saat mengisi data pasien janji temu, pilih jenis jaminan "Asuransi" atau "Perusahaan" dan cantumkan nomor polis atau kartu asuransi Anda.',
    ),
    (
      q: 'Layanan IGD buka jam berapa?',
      a: 'Instalasi Gawat Darurat (IGD) Ciputra Hospital Surabaya beroperasi 24 jam setiap hari dengan dokter siaga dan fasilitas ambulans cepat.',
    ),
    (
      q: 'Bagaimana jika ingin membatalkan atau mengubah jadwal?',
      a: 'Buka menu "Janji Temu" -> "Riwayat", pilih jadwal yang ingin diubah atau dibatalkan, lalu hubungi layanan customer care kami.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Frequently Asked Questions (FAQ)',
              textAlign: TextAlign.center,
              style: AppTypography.headingMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _faqs.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding:
                          const EdgeInsets.only(bottom: AppSpacing.md),
                      title: Text(
                        faq.q,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      children: [
                        Text(
                          faq.a,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
