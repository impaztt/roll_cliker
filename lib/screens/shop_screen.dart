import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/booster_catalog.dart';
import '../data/coaster_part_catalog.dart';
import '../data/exchange_catalog.dart';
import '../data/feature_unlocks.dart';
import '../data/mission_catalog.dart';
import '../models/coaster_part.dart';
import '../providers/game_provider.dart';
import '../widgets/stats_header.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 10),
          TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSoft,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: '소환'),
              Tab(text: '부스터'),
              Tab(text: '환금소'),
              Tab(text: '미션'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                const _SummonTab(),
                const _BoosterTab(),
                const _ExchangeTab(),
                const _MissionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummonTab extends ConsumerWidget {
  const _SummonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '코스터 부품 소환',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '천장: SR+ 미등장 ${GameNotifier.pityThreshold}회 후 다음 1회 SR+ 확정\n현재: ${game.data.summonsSincePity}/${GameNotifier.pityThreshold}',
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: game.data.parkEssence >= GameNotifier.summonCost
                            ? () => notifier.summon()
                            : null,
                        icon: const Icon(Icons.diamond),
                        label: Text('1회 소환 (정수 ${GameNotifier.summonCost})'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: game.data.parkEssence >= GameNotifier.summonCost * 9
                            ? () {
                                for (var i = 0; i < 10; i++) {
                                  notifier.summon();
                                }
                              }
                            : null,
                        child: const Text('10연차 (10% 할인)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '보유 부품',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in coasterPartCatalog)
                      _PartChip(
                        part: p,
                        owned: game.data.ownedParts[p.id] ?? 0,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '세트 보너스',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...coasterSetCatalog.map((s) {
                  final pieces = s.partIds
                      .where((id) => (game.data.ownedParts[id] ?? 0) > 0)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 22,
                          decoration: BoxDecoration(
                            color: s.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '$pieces / ${s.partIds.length}',
                          style: const TextStyle(
                              color: AppColors.textSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PartChip extends StatelessWidget {
  final CoasterPartDef part;
  final int owned;
  const _PartChip({required this.part, required this.owned});

  @override
  Widget build(BuildContext context) {
    final dim = owned == 0;
    return Container(
      width: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (dim ? Colors.grey.shade100 : part.rarity.color.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dim ? Colors.grey.shade300 : part.rarity.color,
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: part.rarity.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              part.rarity.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(part.icon,
              color: dim ? Colors.grey.shade400 : part.rarity.color,
              size: 22),
          const SizedBox(height: 2),
          Text(
            part.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: dim ? Colors.grey : AppColors.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (owned > 0)
            Text(
              '×$owned',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSoft,
              ),
            ),
        ],
      ),
    );
  }
}

class _BoosterTab extends ConsumerWidget {
  const _BoosterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final unlocked =
        notifier.isFeatureUnlocked(FeatureGate.boosterShop);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (!unlocked)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  Icon(Icons.lock, color: AppColors.textSoft),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '리뉴얼 1회 후 부스터 상점이 열립니다.',
                      style: TextStyle(color: AppColors.textSoft),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...boosterCatalog.map((b) => Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_fire_department,
                        color: Color(0xFFEF5350)),
                  ),
                  title: Text(b.name,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(b.description),
                  trailing: ElevatedButton(
                    onPressed: game.data.parkEssence >= b.essenceCost
                        ? () => notifier.useBooster(b.id)
                        : null,
                    child: Text('정수 ${b.essenceCost}'),
                  ),
                ),
              )),
      ],
    );
  }
}

class _ExchangeTab extends ConsumerWidget {
  const _ExchangeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final unlocked = notifier.isFeatureUnlocked(FeatureGate.exchange);
    if (!unlocked) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.lock, color: AppColors.textSoft),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '리뉴얼 1회 또는 누적 코인 100M에서 환금소가 열립니다.',
                  style: TextStyle(color: AppColors.textSoft),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        for (final o in exchangeOffers)
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz,
                  color: Color(0xFFFFAB91), size: 28),
              title: Text(o.name,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                o.flatCoin > 0
                    ? '코인 ${NumberFormatter.format(o.flatCoin)} 즉시 지급'
                    : '현재 CPS의 ${o.cpsMinutes.toInt()}분치 × ${(o.payoutRatio * 100).toInt()}%',
                style: const TextStyle(color: AppColors.textSoft),
              ),
              trailing: ElevatedButton(
                onPressed: game.data.parkEssence >= o.essenceCost
                    ? () => notifier.buyExchange(o.id)
                    : null,
                child: Text('정수 ${o.essenceCost}'),
              ),
            ),
          ),
      ],
    );
  }
}

class _MissionTab extends ConsumerWidget {
  const _MissionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        const _MissionHeader(text: '일일 미션'),
        for (final m in dailyMissions)
          _MissionTile(
            id: m.id,
            title: m.title,
            target: m.target,
            progress:
                game.data.dailyMissionProgress[m.id] ?? 0,
            essence: m.essenceReward,
            prestige: m.prestigeReward,
            claimed: game.data.dailyMissionClaimed.contains(m.id),
            onClaim: () => notifier.claimDailyMission(m.id),
          ),
        const SizedBox(height: 8),
        const _MissionHeader(text: '주간 미션'),
        for (final m in weeklyMissions)
          _MissionTile(
            id: m.id,
            title: m.title,
            target: m.target,
            progress:
                game.data.weeklyMissionProgress[m.id] ?? 0,
            essence: m.essenceReward,
            prestige: m.prestigeReward,
            claimed: game.data.weeklyMissionClaimed.contains(m.id),
            onClaim: () => notifier.claimWeeklyMission(m.id),
          ),
      ],
    );
  }
}

class _MissionHeader extends StatelessWidget {
  final String text;
  const _MissionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.text,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final String id;
  final String title;
  final int target;
  final int progress;
  final int essence;
  final int prestige;
  final bool claimed;
  final VoidCallback onClaim;

  const _MissionTile({
    required this.id,
    required this.title,
    required this.target,
    required this.progress,
    required this.essence,
    required this.prestige,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ready = !claimed && progress >= target;
    final ratio = (progress / target).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (claimed)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF80CBC4), size: 20)
                else
                  ElevatedButton(
                    onPressed: ready ? onClaim : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ready
                          ? const Color(0xFFFFA726)
                          : Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('받기'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: const Color(0xFFFFF3E0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progress / $target  ·  보상 정수 $essence, 명성 $prestige',
              style:
                  const TextStyle(color: AppColors.textSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
