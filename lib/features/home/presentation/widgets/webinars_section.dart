// Upcoming-webinars horizontal carousel.
//
// Each card has:
//   • a 2-stop gradient cover with a date/time chip (or red LIVE pill)
//   • play icon centred on the cover for live sessions
//   • title (2 lines max), instructor row (avatar + name)
//   • bottom row — registered count + "Register" CTA pill

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/webinar.dart';
import 'section_header.dart';

class WebinarsSection extends StatelessWidget {
  const WebinarsSection({super.key, required this.items});
  final List<Webinar> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(eyebrow: 'THIS WEEK', title: 'Upcoming Webinars'),
        SizedBox(
          // Tight — card content is ~220 px + ~12 px Android safety.
          height: R<double>(normal: 232, small: 232, tabletP: 244).resolve(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageGutter),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.cardGap),
            itemBuilder: (context, i) {
              return _WebinarCard(
                webinar: items[i],
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

class _WebinarCard extends StatelessWidget {
  const _WebinarCard({required this.webinar, required this.onTap});
  final Webinar       webinar;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: R<double>(normal: 260, tabletP: 290).resolve(context),
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
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // Cover
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft:  Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                  child: SizedBox(
                    height: 96,
                    width:  double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: webinar.cover,
                              begin: Alignment.topLeft,
                              end:   Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Centred play affordance
                        Center(
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 14, offset: const Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: Icon(
                              webinar.isLive ? Icons.videocam_rounded : Icons.play_arrow_rounded,
                              color: AppColors.accent, size: 26,
                            ),
                          ),
                        ),
                        // Time chip / LIVE pill
                        Positioned(
                          top: 10, left: 10,
                          child: webinar.isLive
                              ? _LivePill()
                              : _TimeChip(label: webinar.whenLabel),
                        ),
                        // Duration chip
                        Positioned(
                          top: 10, right: 10,
                          child: _DurationChip(minutes: webinar.durationMinutes),
                        ),
                      ],
                    ),
                  ),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        webinar.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3.copyWith(fontSize: 13.5, height: 1.25),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InitialAvatar(
                            initial: webinar.instructorInitial,
                            color:   webinar.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              webinar.instructor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11.5,
                                color: AppColors.slate700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              webinar.registeredLabel,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.slate500,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          _RegisterCta(isLive: webinar.isLive),
                        ],
                      ),
                    ],
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

// ── small subpieces ────────────────────────────────────────────────

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.rose,
        borderRadius: AppRadius.rPill,
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withValues(alpha: 0.45),
            blurRadius: 12, spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeOut(duration: 700.ms, curve: Curves.easeInOut),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: AppTypography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 9.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: AppRadius.rPill,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.slate800,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.minutes});
  final int minutes;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.white, size: 10),
          const SizedBox(width: 3),
          Text(
            '${minutes}m',
            style: AppTypography.caption.copyWith(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial, required this.color});
  final String initial;
  final Color  color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: -1),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _RegisterCta extends StatelessWidget {
  const _RegisterCta({required this.isLive});
  final bool isLive;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadius.rPill,
        boxShadow: AppRadius.brandShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLive ? 'Join' : 'Register',
            style: AppTypography.buttonLabel.copyWith(fontSize: 11.5),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
        ],
      ),
    );
  }
}
