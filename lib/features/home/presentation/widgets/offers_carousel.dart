// "Popular courses" horizontal carousel.
//
// Each card is a richly-composed 280-wide premium tile:
//   • 3-stop gradient cover with subtle dot-grid texture
//   • Top-right badge (HOT / NEW / BESTSELLER) when present
//   • Centered play button on the cover
//   • Title, level chip and duration footnote
//   • Stacked instructor avatars with "+N more"
//   • Star rating + learner count
//   • Bottom row — strike-through price + discounted price
//   • If the user already has progress, an inline resume bar replaces
//     the discount row on the cover.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/course_offer.dart';

class OffersCarousel extends StatelessWidget {
  const OffersCarousel({
    super.key,
    required this.courses,
    this.onCourseTap,
  });

  final List<CourseOffer> courses;
  final ValueChanged<CourseOffer>? onCourseTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        // Top = AppSpacing.section (30); Bottom = AppSpacing.headerToContent (20).
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter + 4, AppSpacing.section,
            AppSpacing.pageGutter + 4, AppSpacing.headerToContent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOP PICKS', style: AppTypography.eyebrow),
                  const SizedBox(height: 4),
                  Text('Popular Courses', style: AppTypography.h2),
                ],
              ),
              const Spacer(),
              _SeeAllChip(onTap: () {}),
            ],
          ),
        ),

        // ── Carousel ────────────────────────────────────────────────
        SizedBox(
          height: 318,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
            itemBuilder: (context, i) {
              final c = courses[i];
              return _CourseCard(
                course: c,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCourseTap?.call(c);
                },
              ).animate(delay: (80 * i).ms).fadeIn(duration: 420.ms).slideX(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Course card
// ─────────────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final CourseOffer  course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 274,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rLg,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rLg,
              boxShadow: AppRadius.cardShadow,
              border: Border.all(color: AppColors.outlineSoft, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Cover(course: course),
                _Body(course: course),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cover — gradient + play button + badge + (optional) progress
// ─────────────────────────────────────────────────────────────────────

class _Cover extends StatelessWidget {
  const _Cover({required this.course});
  final CourseOffer course;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft:  Radius.circular(AppRadius.lg),
        topRight: Radius.circular(AppRadius.lg),
      ),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                  colors: course.cover,
                ),
              ),
            ),
            // Texture overlay — repeated dot grid for material feel.
            Positioned.fill(
              child: CustomPaint(painter: _CoverDotPainter()),
            ),
            // Soft bottom shade so text in body reads better at the join.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Centred play button.
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.accent,
                  size: 32,
                ),
              ),
            ),

            // Badge (HOT / NEW / BESTSELLER).
            if (course.badge != null)
              Positioned(top: 10, left: 10, child: _Badge(label: course.badge!)),

            // Level pill (top-right).
            Positioned(
              top: 10,
              right: 10,
              child: _LevelPill(label: course.level),
            ),

            // Progress strip (bottom).
            if (course.progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ProgressStrip(value: course.progress),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Card body — title, meta, rating, price
// ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.course});
  final CourseOffer course;

  @override
  Widget build(BuildContext context) {
    final resumed = course.progress > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(fontSize: 14, height: 1.25),
          ),
          const SizedBox(height: 4),
          Text(
            course.duration,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.slate500,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),

          // Instructors + rating row.
          Row(
            children: [
              _InstructorStack(
                accents: course.instructorAccents,
                extra: course.extraInstructors,
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, color: AppColors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                course.rating.toStringAsFixed(1),
                style: AppTypography.caption.copyWith(
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${course.displayLearners})',
                style: AppTypography.caption.copyWith(
                  color: AppColors.slate500,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Price / Resume CTA.
          if (resumed)
            _ResumeCta(progress: course.progress)
          else
            _PriceRow(course: course),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Subwidgets
// ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  Color _bgFor(String s) {
    switch (s) {
      case 'HOT':         return AppColors.rose;
      case 'NEW':         return AppColors.success;
      case 'BESTSELLER':  return AppColors.amber;
      default:            return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.rPill,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: AppRadius.rPill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.rPill,
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).round()}%',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorStack extends StatelessWidget {
  const _InstructorStack({required this.accents, required this.extra});

  final List<Color> accents;
  final int extra;

  @override
  Widget build(BuildContext context) {
    final visible = accents.take(3).toList();
    return SizedBox(
      height: 22,
      width: visible.length * 16.0 + 6 + (extra > 0 ? 26 : 0),
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: visible[i],
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: visible[i].withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: -1,
                    ),
                  ],
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible.length * 14.0,
              child: Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: AppRadius.rPill,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.course});
  final CourseOffer course;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          course.displayPrice,
          style: AppTypography.h3.copyWith(
            color: AppColors.accent600,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            course.displayOriginalPrice,
            style: AppTypography.caption.copyWith(
              color: AppColors.slate400,
              fontSize: 11,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
            shape: BoxShape.circle,
            boxShadow: AppRadius.brandShadow,
          ),
          child: const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 16),
        ),
      ],
    );
  }
}

class _ResumeCta extends StatelessWidget {
  const _ResumeCta({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadius.rPill,
        boxShadow: AppRadius.brandShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            'Resume · ${(progress * 100).round()}%',
            style: AppTypography.buttonLabel.copyWith(fontSize: 12),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// "See all" chip — duplicated locally to keep the file self-contained.
// ─────────────────────────────────────────────────────────────────────

class _SeeAllChip extends StatelessWidget {
  const _SeeAllChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: AppRadius.rPill,
          border: Border.all(color: AppColors.brand200, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'See all',
              style: AppTypography.caption.copyWith(
                color: AppColors.brand700,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded,
                size: 13, color: AppColors.brand700),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Dot grid painter for the cover texture.
// ─────────────────────────────────────────────────────────────────────

class _CoverDotPainter extends CustomPainter {
  static const double _step    = 18;
  static const double _radius  = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (double y = _step / 2; y < size.height; y += _step) {
      for (double x = _step / 2; x < size.width; x += _step) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverDotPainter oldDelegate) => false;
}
