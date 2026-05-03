import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/skill_catalog.dart';
import '../providers/game_provider.dart';
import '../widgets/coaster_scene.dart';
import '../widgets/floating_number.dart';
import '../widgets/golden_guest_widget.dart';
import '../widgets/headline_card.dart';
import '../widgets/offline_reward_dialog.dart';
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen isometric scene ─────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) {
              final size = MediaQuery.of(context).size;
              final origin = Offset(
                e.localPosition.dx / size.width,
                e.localPosition.dy / size.height,
              );
              ref.read(gameProvider.notifier).onTap(origin);
            },
            child: const CoasterScene(),
          ),
        ),

        // ── Floating numbers + toasts overlay (full screen) ─────────
        Positioned.fill(
          child: LayoutBuilder(builder: (ctx, c) {
            return FloatingNumberLayer(
              items: game.floats,
              size: Size(c.maxWidth, c.maxHeight),
            );
          }),
        ),
        Positioned.fill(child: ToastOverlay(toasts: game.toasts)),

        // ── Top HUD (coin + level progress) ─────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _TopHud(),
          ),
        ),

        // ── Phase chip + combo (just below HUD) ─────────────────────
        Positioned(
          top: 70,
          left: 14,
          child: _PhaseChip(phase: game.ride.phase),
        ),
        Positioned(
          top: 70,
          right: 14,
          child: _ComboChip(combo: game.data.currentCombo),
        ),

        // ── Golden guest ────────────────────────────────────────────
        if (game.golden != null)
          Positioned(
            left: 24,
            bottom: 220,
            child: GoldenGuestWidget(
              guest: game.golden!,
              onTap: () => ref
                  .read(gameProvider.notifier)
                  .onTapGolden(const Offset(0.18, 0.6)),
            ),
          ),

        // ── Bottom: 3 headline upgrade cards + skill rail ───────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SkillRail(),
                  const SizedBox(height: 8),
                  _HeadlineRow(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopHud extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final stage = game.coasterStage;
    final next = stage + 1;
    final lo = coasterStageThresholdsDouble[stage].toDouble();
    final hi = next < coasterStageThresholdsDouble.length
        ? coasterStageThresholdsDouble[next].toDouble()
        : lo * 10;
    final progress =
        ((game.data.totalCoinEarned - lo) / (hi - lo)).clamp(0.0, 1.0);
    return Row(
      children: [
        // Settings stub
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Icon(Icons.settings,
              color: Color(0xFF8D6E63), size: 20),
        ),
        const SizedBox(width: 8),
        // Coin badge
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money,
                    color: Color(0xFFFFA726), size: 20),
                const SizedBox(width: 4),
                Text(
                  NumberFormatter.format(game.data.coin),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Level chip + progress
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lv ${stage + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 70,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF80CBC4)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeadlineRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final d = game.data;

    final ticketCostNext = ticketCost(d.ticketLevel + 1);
    final speedCostNext = speedCost(d.speedLevel + 1);
    final carsCostNext = carsCost(d.carsLevel + 1);
    final speedMax = d.speedLevel >= speedMaxLevel;
    final carsMax = d.carsLevel >= carsMaxLevel;

    return Row(
      children: [
        Expanded(
          child: HeadlineCard(
            icon: Icons.confirmation_num,
            color: const Color(0xFFFF7043),
            label: 'Ticket',
            level: d.ticketLevel,
            cost: ticketCostNext,
            affordable: d.coin >= ticketCostNext,
            onBuy: notifier.buyTicket,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HeadlineCard(
            icon: Icons.speed,
            color: const Color(0xFF66BB6A),
            label: 'Speed',
            level: d.speedLevel,
            cost: speedCostNext,
            affordable: !speedMax && d.coin >= speedCostNext,
            isMax: speedMax,
            onBuy: notifier.buySpeed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HeadlineCard(
            icon: Icons.directions_railway,
            color: const Color(0xFF42A5F5),
            label: 'Cars',
            level: d.carsLevel,
            cost: carsCostNext,
            affordable: !carsMax && d.coin >= carsCostNext,
            isMax: carsMax,
            onBuy: notifier.buyCars,
          ),
        ),
      ],
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
  const _SkillRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameProvider); // rebuild on cooldown changes
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: skillCatalog.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = skillCatalog[i];
          final cd =
              ref.read(gameProvider.notifier).skillCooldownLeft(s.id);
          final ready = cd == null;
          return InkWell(
            onTap: ready
                ? () => ref.read(gameProvider.notifier).useSkill(s.id)
                : null,
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: ready
                    ? Colors.white
                    : Colors.grey.shade300.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ready ? s.accent : Colors.transparent,
                  width: 2,
                ),
                boxShadow: ready
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s.icon,
                    color: ready ? s.accent : Colors.grey.shade500,
                    size: 22,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    ready
                        ? s.name
                        : NumberFormatter.formatTime(cd),
                    style: TextStyle(
                      fontSize: 9,
                      color: ready
                          ? AppColors.text
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
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
