class ExchangeOffer {
  final String id;
  final String name;
  final int essenceCost;
  // If `cpsMinutes > 0`, payout = currentCps × seconds × payoutRatio.
  // Else, fixed `flatCoin` is granted.
  final double cpsMinutes;
  final double flatCoin;
  final double payoutRatio;
  final bool oncePerDay;

  const ExchangeOffer({
    required this.id,
    required this.name,
    required this.essenceCost,
    this.cpsMinutes = 0,
    this.flatCoin = 0,
    this.payoutRatio = 0.85,
    this.oncePerDay = false,
  });
}

const exchangeOffers = <ExchangeOffer>[
  ExchangeOffer(
    id: 'cps_5m',
    name: '5분 환금',
    essenceCost: 12,
    cpsMinutes: 5,
  ),
  ExchangeOffer(
    id: 'cps_30m',
    name: '30분 환금',
    essenceCost: 50,
    cpsMinutes: 30,
  ),
  ExchangeOffer(
    id: 'cps_2h',
    name: '2시간 환금',
    essenceCost: 180,
    cpsMinutes: 120,
  ),
  ExchangeOffer(
    id: 'cps_8h',
    name: '8시간 환금 (일 1회)',
    essenceCost: 600,
    cpsMinutes: 480,
    oncePerDay: true,
  ),
  ExchangeOffer(
    id: 'flat_1m',
    name: '긴급 자금 1M',
    essenceCost: 5,
    flatCoin: 1e6,
    payoutRatio: 1,
  ),
  ExchangeOffer(
    id: 'flat_50m',
    name: '긴급 자금 50M',
    essenceCost: 20,
    flatCoin: 5e7,
    payoutRatio: 1,
  ),
  ExchangeOffer(
    id: 'flat_500m',
    name: '긴급 자금 500M',
    essenceCost: 80,
    flatCoin: 5e8,
    payoutRatio: 1,
  ),
  ExchangeOffer(
    id: 'flat_3b',
    name: '긴급 자금 3B',
    essenceCost: 300,
    flatCoin: 3e9,
    payoutRatio: 1,
  ),
];
