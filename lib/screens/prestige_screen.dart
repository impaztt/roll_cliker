import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/prestige_upgrade_catalog.dart';
import '../providers/game_provider.dart';
import '../widgets/stats_header.dart';

class PrestigeScreen extends ConsumerWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final potential = notifier.prestigePotential();
    final canPrestige = notifier.canPrestige();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFFFFF3E0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '리뉴얼 오픈',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '롤러코스터를 새로 단장하고 영구 명성을 얻습니다.',
                    style:
                        const TextStyle(color: AppColors.textSoft, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: '획득 가능 명성',
                        value: '+${NumberFormatter.formatInt(potential)}',
                        color: const Color(0xFFFFA726),
                      ),
                      _StatColumn(
                        label: '현재 명성',
                        value: NumberFormatter.formatInt(game.data.prestigePoints),
                        color: const Color(0xFFFFCA28),
                      ),
                      _StatColumn(
                        label: '리뉴얼 횟수',
                        value: NumberFormatter.formatInt(game.data.prestigeCount),
                        color: const Color(0xFF80CBC4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: canPrestige
                        ? () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('리뉴얼 진행'),
                                content: Text(
                                  '코인, 탭/자동 강화 레벨이 초기화됩니다.\n명성 +$potential 획득.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('진행'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) notifier.prestige();
                          }
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: Text(canPrestige
                        ? '리뉴얼 오픈 (+$potential 명성)'
                        : '명성 1 이상 가능 시'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '명성 강화',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: prestigeUpgradeCatalog.length,
              itemBuilder: (_, i) {
                final u = prestigeUpgradeCatalog[i];
                final lv = game.data.prestigeUpgradeLevels[u.id] ?? 0;
                final cost = u.costForLevel(lv);
                final affordable = game.data.prestigePoints >= cost;
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: u.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(u.icon, color: u.accent),
                    ),
                    title: Text(u.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${u.description} · Lv.$lv'),
                    trailing: ElevatedButton(
                      onPressed:
                          affordable ? () => notifier.buyPrestigeUpgrade(u.id) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            affordable ? u.accent : Colors.grey.shade300,
                      ),
                      child: Text('명성 $cost'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
            )),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
