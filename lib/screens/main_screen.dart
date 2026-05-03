import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/feature_unlocks.dart';
import '../providers/game_provider.dart';
import 'home_screen.dart';
import 'prestige_screen.dart';
import 'shop_screen.dart';
import 'stock_market_screen.dart';
import 'upgrade_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    if (!game.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pages = const <Widget>[
      HomeScreen(),
      UpgradeScreen(),
      ShopScreen(),
      StockMarketScreen(),
      PrestigeScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        marketUnlocked: ref
            .read(gameProvider.notifier)
            .isFeatureUnlocked(FeatureGate.stockMarket),
        prestigeUnlocked: ref
            .read(gameProvider.notifier)
            .isFeatureUnlocked(FeatureGate.prestige),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool marketUnlocked;
  final bool prestigeUnlocked;

  const _BottomNav({
    required this.index,
    required this.onTap,
    required this.marketUnlocked,
    required this.prestigeUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _navItem(0, Icons.home_filled, '홈'),
            _navItem(1, Icons.trending_up, '강화'),
            _navItem(2, Icons.shopping_bag, '상점'),
            _navItem(3, Icons.show_chart, '투자',
                disabled: !marketUnlocked, hint: '1B 코인 누적'),
            _navItem(4, Icons.refresh, '리뉴얼',
                disabled: !prestigeUnlocked, hint: '명성 1+ 가능'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label,
      {bool disabled = false, String? hint}) {
    final active = i == index;
    final color = disabled
        ? Colors.grey.shade400
        : (active ? AppColors.primary : AppColors.textSoft);
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => onTap(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                disabled && hint != null ? hint : label,
                style: TextStyle(
                  color: color,
                  fontSize: disabled && hint != null ? 9 : 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
