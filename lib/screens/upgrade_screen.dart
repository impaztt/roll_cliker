import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../data/producer_catalog.dart';
import '../data/tap_upgrade_catalog.dart';
import '../providers/game_provider.dart';
import '../widgets/stats_header.dart';
import '../widgets/upgrade_tile.dart';

class UpgradeScreen extends ConsumerStatefulWidget {
  const UpgradeScreen({super.key});

  @override
  ConsumerState<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends ConsumerState<UpgradeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 10),
          TabBar(
            controller: _tab,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: const Color(0xFF8D6E63),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: '응원 / 출발 (탭)'),
              Tab(text: '자동 운영 (CPS)'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildTapList(game),
                _buildAutoList(game),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapList(GameState game) {
    final notifier = ref.read(gameProvider.notifier);
    final unlocked = <int>[];
    for (var i = 0; i < tapUpgradeCatalog.length; i++) {
      if (i == 0 ||
          (game.data.tapUpgradeLevels[tapUpgradeCatalog[i - 1].id] ?? 0) > 0 ||
          game.data.coin >= tapUpgradeCatalog[i].baseCost / 4) {
        unlocked.add(i);
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: unlocked.length,
      itemBuilder: (_, idx) {
        final i = unlocked[idx];
        final u = tapUpgradeCatalog[i];
        final lv = game.data.tapUpgradeLevels[u.id] ?? 0;
        final cost = u.costForLevel(lv);
        return UpgradeTile(
          icon: u.icon,
          accent: u.accent,
          title: u.name,
          subtitle: '${u.description} · 누적 +${NumberFormatter.formatPrecise(u.tapPowerPerLevel * lv)}',
          level: lv,
          cost: cost,
          affordable: game.data.coin >= cost,
          onBuy: () => notifier.buyTapUpgrade(u.id),
        );
      },
    );
  }

  Widget _buildAutoList(GameState game) {
    final notifier = ref.read(gameProvider.notifier);
    final unlocked = <int>[];
    for (var i = 0; i < producerCatalog.length; i++) {
      if (i == 0 ||
          (game.data.autoProducerLevels[producerCatalog[i - 1].id] ?? 0) > 0 ||
          game.data.coin >= producerCatalog[i].baseCost / 4) {
        unlocked.add(i);
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: unlocked.length,
      itemBuilder: (_, idx) {
        final i = unlocked[idx];
        final p = producerCatalog[i];
        final lv = game.data.autoProducerLevels[p.id] ?? 0;
        final cost = p.costForLevel(lv);
        final cps = p.cpsAtLevel(lv);
        final ms = p.nextMilestone(lv);
        return UpgradeTile(
          icon: p.icon,
          accent: p.accent,
          title: p.name,
          subtitle: '${p.description}\nCPS ${NumberFormatter.format(cps)}',
          level: lv,
          cost: cost,
          affordable: game.data.coin >= cost,
          onBuy: () => notifier.buyAutoProducer(p.id),
          milestoneText: ms == null
              ? null
              : '다음 마일스톤 Lv.${ms.nextLevel} → ×${ms.mult.toStringAsFixed(0)}',
        );
      },
    );
  }
}
