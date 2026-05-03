import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/number_format.dart';
import '../core/theme.dart';
import '../data/feature_unlocks.dart';
import '../data/park_stock_catalog.dart';
import '../models/stock_market.dart';
import '../providers/game_provider.dart';
import '../widgets/candle_chart.dart';
import '../widgets/stats_header.dart';

class StockMarketScreen extends ConsumerWidget {
  const StockMarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    if (!notifier.isFeatureUnlocked(FeatureGate.stockMarket)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '누적 코인 1B 달성 시 주식 시장이 열립니다.',
            style: TextStyle(color: AppColors.textSoft),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final game = ref.watch(gameProvider);
    final unlocked = parkStockCatalog
        .where((s) => game.data.market.stocks[s.id]?.unlocked ?? false)
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          const StatsHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: unlocked.length,
              itemBuilder: (_, i) {
                final def = unlocked[i];
                final state = game.data.market.stocks[def.id]!;
                return _StockCard(def: def, state: state);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends ConsumerStatefulWidget {
  final StockDef def;
  final StockState state;
  const _StockCard({required this.def, required this.state});

  @override
  ConsumerState<_StockCard> createState() => _StockCardState();
}

class _StockCardState extends ConsumerState<_StockCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final ratio = s.shares / totalSharesPerStock;
    final pnl = s.shares == 0 || s.avgCost == 0
        ? 0.0
        : (s.currentPrice - s.avgCost) / s.avgCost;
    final pnlColor = pnl >= 0
        ? const Color(0xFFEF5350)
        : const Color(0xFF42A5F5);
    final game = ref.watch(gameProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.def.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(widget.def.sector,
                            style: const TextStyle(
                                color: AppColors.textSoft, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormatter.format(s.currentPrice),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      Text(
                        '${(ratio * 100).toStringAsFixed(2)}% 보유',
                        style: const TextStyle(
                            color: AppColors.textSoft, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (s.shares > 0)
                    _Pill(
                      color: pnlColor.withValues(alpha: 0.15),
                      textColor: pnlColor,
                      text:
                          '평가손익 ${pnl >= 0 ? '+' : ''}${(pnl * 100).toStringAsFixed(1)}%',
                    ),
                  const SizedBox(width: 6),
                  if (s.pendingDividend > 0)
                    _Pill(
                      color: const Color(0xFFFFCA28).withValues(alpha: 0.18),
                      textColor: const Color(0xFFFFA726),
                      text:
                          '배당 +${NumberFormatter.format(s.pendingDividend)}',
                    ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                if (s.recentCandles.length >= 2)
                  SizedBox(
                    height: 100,
                    child: CandleChart(candles: s.recentCandles),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        '차트 데이터를 모으는 중...',
                        style:
                            TextStyle(color: AppColors.textSoft, fontSize: 11),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: game.data.coin >=
                                s.currentPrice * (1 + tradeFeeRate)
                            ? () => ref
                                .read(gameProvider.notifier)
                                .buyShares(widget.def.id, 1)
                            : null,
                        child: const Text('1주 매수'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: game.data.coin >=
                                s.currentPrice * 10 * (1 + tradeFeeRate)
                            ? () => ref
                                .read(gameProvider.notifier)
                                .buyShares(widget.def.id, 10)
                            : null,
                        child: const Text('10주 매수'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: s.shares >= 1
                            ? () => ref
                                .read(gameProvider.notifier)
                                .sellShares(widget.def.id, 1)
                            : null,
                        child: const Text('1주 매도'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: s.shares >= 10
                            ? () => ref
                                .read(gameProvider.notifier)
                                .sellShares(widget.def.id, s.shares)
                            : null,
                        child: const Text('전량 매도'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: s.pendingDividend > 0
                            ? () => ref
                                .read(gameProvider.notifier)
                                .claimDividend(widget.def.id)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCA28),
                        ),
                        child: const Text('배당 수령'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '평균단가 ${NumberFormatter.format(s.avgCost)} · 시간당 배당률 ${(widget.def.dividendRate * 100).toStringAsFixed(0)}% · 변동성 ${(widget.def.volatility * 100).toStringAsFixed(2)}%',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textSoft),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String text;
  const _Pill({
    required this.color,
    required this.textColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
