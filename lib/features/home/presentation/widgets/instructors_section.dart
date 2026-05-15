// Top-instructors horizontal rail.
//
// Compact white cards — large gradient avatar + name + specialty +
// star rating + student/course counts. Verified instructors get a
// small blue check beside their name.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/instructor.dart';
import 'section_header.dart';

class InstructorsSection extends StatelessWidget {
  const InstructorsSection({super.key, required this.items});
  final List<Instructor> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(eyebrow: 'LEARN FROM THE BEST', title: 'Top Instructors'),
        // Auto-sizing carousel — fixes the 6 px Android overflow.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.cardGap),
                  _InstructorCard(
                    instructor: items[i],
                    onTap: () => HapticFeedback.selectionClick(),
                  ).animate(delay: (60 * i).ms).fadeIn(duration: 380.ms).slideX(
                        begin: 0.08, end: 0, curve: Curves.easeOutCubic,
                      ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructorCard extends StatelessWidget {
  const _InstructorCard({required this.instructor, required this.onTap});
  final Instructor    instructor;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: R<double>(normal: 174, tabletP: 190).resolve(context),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.rLg,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.rLg,
                boxShadow: AppRadius.cardShadow,
                border: Border.all(color: AppColors.outlineSoft, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                _Avatar(initial: instructor.initial, gradient: instructor.avatarGradient),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        instructor.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3.copyWith(fontSize: 12.5),
                      ),
                    ),
                    if (instructor.verified) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.verified_rounded,
                          size: 13, color: AppColors.sky500),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  instructor.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.slate500,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text(
                      instructor.rating.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(
                      color: AppColors.slate300, shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      '${instructor.courseCount} courses',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.slate500, fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: AppRadius.rPill,
                    border: Border.all(color: AppColors.brand200, width: 1),
                  ),
                  child: Text(
                    instructor.studentsLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brand700,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.gradient});
  final String       initial;
  final List<Color>  gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.40),
            blurRadius: 14, offset: const Offset(0, 6), spreadRadius: -2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
