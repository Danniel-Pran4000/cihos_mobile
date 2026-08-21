import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/textured_background.dart';
import '../data/health_news_repository.dart';
import '../domain/health_article.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/staggered_entrance.dart';

/// The health-news feed: two swipeable shelves over a list of saved reads.
class HealthNewsScreen extends ConsumerWidget {
  const HealthNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(articlesByShelfProvider(ArticleShelf.latest));
    final others = ref.watch(articlesByShelfProvider(ArticleShelf.others));
    final reading = ref.watch(articlesByShelfProvider(ArticleShelf.reading));

    return Scaffold(
      body: TexturedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Info Kesehatan'),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    // Berita Terbaru Section
                    const _ShelfTitle('Berita Terbaru'),
                    const SizedBox(height: AppSpacing.sm),
                    _Carousel(articles: latest),
                    const SizedBox(height: AppSpacing.xxl),

                    // Lainnya Section
                    const _ShelfTitle('Lainnya'),
                    const SizedBox(height: AppSpacing.sm),
                    _Carousel(articles: others),
                    const SizedBox(height: AppSpacing.xxl),

                    // Bacaan Anda Section
                    const _ShelfTitle('Bacaan Anda'),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          for (final article in reading) ...[
                            Pressable(
                              scale: 0.98,
                              child: _ReadingRow(article: article),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShelfTitle extends StatelessWidget {
  const _ShelfTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
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
            text,
            style: AppTypography.headingMd.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontally swipeable strip of article cards with proper spacing.
class _Carousel extends StatelessWidget {
  const _Carousel({required this.articles});

  final List<HealthArticle> articles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 4,
        ),
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) => StaggeredEntrance(
          index: index,
          child: Pressable(
            scale: 0.97,
            child: _CarouselCard(article: articles[index]),
          ),
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _Cover(article: article),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy', 'id_ID').format(article.date),
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13.5,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Baca Selengkapnya',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A saved read row: thumbnail left, headline and "Baca Selengkapnya" right.
class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentSoft.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 110,
              height: 85,
              child: _Cover(article: article),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(article.date),
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Baca Selengkapnya',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The article cover, or a tinted placeholder while the export is missing.
class _Cover extends StatelessWidget {
  const _Cover({required this.article});

  final HealthArticle article;

  @override
  Widget build(BuildContext context) {
    if (article.imageAsset == null) return const _CoverPlaceholder();

    return Image.asset(
      article.imageAsset!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _CoverPlaceholder(),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ImagePlaceholder(icon: Icons.article_outlined, iconSize: 32);
  }
}
