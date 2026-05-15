// Student-review horizontal carousel.
//
// Each card has a quote-mark watermark, the rating stars row, the
// review body (clamped to 4 lines), and a bottom row with the
// student avatar/name + the course they took.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/review.dart';
import 'section_header.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({super.key, required this.items});
  final List<Review> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(eyebrow: 'LOVED BY LEARNERS', title: 'Student Reviews'),
        SizedBox(
          // Tight — card content is ~175 px + ~15 px Android safety.
          height: R<double>(normal: 190, small: 190, tabletP: 200).resolve(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
            itemBuilder: (context, i) {
              return _ReviewCard(
                review: items[i],
                onTap: () => HapticFeedback.selectionClick(),
              ).animate(delay: (60 * i).ms).fadeIn(duration: 380.ms).slideX(
                    begin: 0.08, end: 0, curve: Curves.easeOutCubic,
                  );
            },
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onTap});
  final Review        review;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    // Align(topCenter) + mainAxisSize.min on the Column = card sizes
    // to its content height; no stretching to fill the carousel.
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: R<double>(normal: 286, tabletP: 320).resolve(context),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.rLg,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.rLg,
                boxShadow: AppRadius.cardShadow,
                border: Border.all(color: AppColors.outlineSoft, width: 1),
              ),
              child: Stack(
                children: [
                // Watermark quote glyph
                Positioned(
                  top: -8, right: -4,
                  child: Text(
                    '"',
                    style: TextStyle(
                      fontSize: 88,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand100.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stars
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < review.rating.round();
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: filled ? AppColors.amber : AppColors.slate200,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Body — plain Text (was Expanded). maxLines:4 +
                    // ellipsis already caps the size; intrinsic height
                    // is what we want so the card hugs the content.
                    Text(
                      review.comment,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.slate700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.7)),
                    const SizedBox(height: 10),
                    // Footer — avatar + name + course
                    Row(
                      children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: review.avatarColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: review.avatarColor.withValues(alpha: 0.35),
                                blurRadius: 8, spreadRadius: -2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            review.studentInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h3.copyWith(fontSize: 12.5),
                              ),
                              Text(
                                review.courseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.slate500,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
