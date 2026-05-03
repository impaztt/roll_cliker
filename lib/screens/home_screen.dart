import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/skill_catalog.dart';
import '../providers/game_provider.dart';
import '../widgets/coaster_scene.dart';
import '../widgets/floating_number.dart';
import '../widgets/golden_guest_widget.dart';
import '../widgets/offline_reward_dialog.dart';
import '../widgets/stats_header.dart';
import '../widgets/toast_overlay.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _offlineShown = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_offlineShown && game.offlineRewardPending) {
        _offlineShown = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => OfflineRewardDialog(
            amount: game.offlineRewardAmount,
            duration: game.offlineRewardDuration,
            onClaim: () {
              Navigator.of(context).pop();
              ref.read(gameProvider.notifier).clearOfflineReward();
            },
          ),
        );
      }
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (ctx, c) {
              return Stack(
                children: [
                  // Tap-zone scene
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (e) {
                          final origin = Offset(
                            e.localPosition.dx / c.maxWidth,
                            e.localPosition.dy / c.maxHeight,
                          );
                          ref.read(gameProvider.notifier).onTap(origin);
                        },
                        child: const CoasterScene(),
                      ),
                    ),
                  ),
                  // Phase indicator
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _PhaseChip(phase: game.ride.phase),
                  ),
                  // Combo
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _ComboChip(combo: game.data.currentCombo),
                  ),
                  // Floating numbers (taps)
                  Positioned.fill(
                    child: FloatingNumberLayer(
                      items: game.floats,
                      size: Size(c.maxWidth, c.maxHeight),
                    ),
                  ),
                  // Golden guest
                  if (game.golden != null)
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: GoldenGuestWidget(
                        guest: game.golden!,
                        onTap: () {
                          ref.read(gameProvider.notifier).onTapGolden(
                                const Offset(0.18, 0.6),
                              );
                        },
                      ),
                    ),
                  // Toasts
                  Positioned.fill(
                    child: ToastOverlay(toasts: game.toasts),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 8),
          _SkillRail(),
        ],
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  final RidePhase phase;
  const _PhaseChip({required this.phase});

  String get _label {
    switch (phase) {
      case RidePhase.waitingForGuests:
        return '손님 입장 대기';
      case RidePhase.boarding:
        return '탑승 안내';
      case RidePhase.seating:
        return '착석';
      case RidePhase.safetyBar:
        return '안전바 점검';
      case RidePhase.ready:
        return '출발 준비';
      case RidePhase.riding:
        return '운행 중';
      case RidePhase.arriving:
        return '도착';
      case RidePhase.unboarding:
        return '하차 / 정산';
    }
  }

  Color get _color {
    switch (phase) {
      case RidePhase.riding:
        return const Color(0xFFEF5350);
      case RidePhase.unboarding:
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF80CBC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.directions_railway,
              color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboChip extends StatelessWidget {
  final int combo;
  const _ComboChip({required this.combo});

  @override
  Widget build(BuildContext context) {
    if (combo == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8A65).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '콤보 x$combo',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SkillRail extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameProvider); // rebuild on cooldown changes
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: skillCatalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = skillCatalog[i];
          final cd = ref.read(gameProvider.notifier).skillCooldownLeft(s.id);
          final ready = cd == null;
          return InkWell(
            onTap: ready
                ? () => ref.read(gameProvider.notifier).useSkill(s.id)
                : null,
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: ready
                    ? s.accent.withValues(alpha: 0.18)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ready ? s.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s.icon,
                    color: ready ? s.accent : Colors.grey.shade500,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.name,
                    style: TextStyle(
                      fontSize: 9,
                      color: ready
                          ? AppColors.text
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!ready)
                    Text(
                      NumberFormatter.formatTime(cd),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
