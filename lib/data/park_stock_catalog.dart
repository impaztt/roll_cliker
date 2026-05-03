import '../models/stock_market.dart';

/// All-time gold trigger to unlock the stock market UI.
const double stockMarketLifetimeCoinTrigger = 1e9;

/// Per-stock total share count.
const int totalSharesPerStock = 10000000;

/// Trade fee fraction (applied to both buy and sell).
const double tradeFeeRate = 0.02;

/// Price tick interval.
const Duration priceTickInterval = Duration(seconds: 1);

/// Length of one candle.
const Duration candleSpan = Duration(seconds: 30);

/// How many recent candles we keep per stock.
const int maxCandlesPerStock = 60;

/// Dividend accrual interval.
const Duration dividendInterval = Duration(hours: 1);

/// Maximum ownership ratio of a single stock (0..1).
const double maxOwnershipRatio = 0.80;

/// Required ownership of previous stock to unlock the next one.
const double unlockOwnershipRatio = 0.20;

/// Floor & ceiling around intrinsic price.
const double priceFloorMultiple = 0.10;
const double priceCeilingMultiple = 18.5;

/// Base intrinsic price for the first stock.
/// Cap = 1e17 coin, total shares = 1e7 → 1e10 per share.
const double basePricePerShare = 1e10;

const parkStockCatalog = <StockDef>[
  StockDef(
    id: 'coasterworks',
    name: '코스터웍스',
    sector: '기본 코스터 제작',
    capScale: 1.0,
    volatility: 0.0075,
    dividendRate: 0.08,
    order: 1,
  ),
  StockDef(
    id: 'parkgate',
    name: '파크게이트',
    sector: '입장/게이트',
    capScale: 10.0,
    volatility: 0.0090,
    dividendRate: 0.08,
    order: 2,
  ),
  StockDef(
    id: 'queueline',
    name: '큐라인',
    sector: '대기열 시스템',
    capScale: 10.5,
    volatility: 0.0075,
    dividendRate: 0.09,
    order: 3,
  ),
  StockDef(
    id: 'safebar',
    name: '세이프바',
    sector: '안전바/안전장비',
    capScale: 11.0,
    volatility: 0.0075,
    dividendRate: 0.09,
    order: 4,
  ),
  StockDef(
    id: 'luckysnack',
    name: '럭키스낵',
    sector: '대기 간식 판매',
    capScale: 11.5,
    volatility: 0.0060,
    dividendRate: 0.10,
    order: 5,
  ),
  StockDef(
    id: 'photostar',
    name: '포토스타',
    sector: '하차 사진 서비스',
    capScale: 12.0,
    volatility: 0.0105,
    dividendRate: 0.10,
    order: 6,
  ),
  StockDef(
    id: 'dreamgoods',
    name: '드림굿즈',
    sector: '기념품',
    capScale: 12.5,
    volatility: 0.0105,
    dividendRate: 0.10,
    order: 7,
  ),
  StockDef(
    id: 'lumientertainment',
    name: '루미엔터',
    sector: '공연/이벤트',
    capScale: 13.0,
    volatility: 0.0090,
    dividendRate: 0.09,
    order: 8,
  ),
  StockDef(
    id: 'coastersns',
    name: '코스터SNS',
    sector: '바이럴 홍보',
    capScale: 13.5,
    volatility: 0.0090,
    dividendRate: 0.09,
    order: 9,
  ),
  StockDef(
    id: 'neonlight',
    name: '네온라이트',
    sector: '야간 조명',
    capScale: 14.0,
    volatility: 0.0105,
    dividendRate: 0.10,
    order: 10,
  ),
  StockDef(
    id: 'mecharail',
    name: '메카레일',
    sector: '정비/레일',
    capScale: 14.5,
    volatility: 0.0120,
    dividendRate: 0.10,
    order: 11,
  ),
  StockDef(
    id: 'stormbooster',
    name: '스톰부스터',
    sector: '발사 장치',
    capScale: 15.0,
    volatility: 0.0105,
    dividendRate: 0.11,
    order: 12,
  ),
  StockDef(
    id: 'vipline',
    name: 'VIP라인',
    sector: '프리미엄 대기열',
    capScale: 15.5,
    volatility: 0.0090,
    dividendRate: 0.10,
    order: 13,
  ),
  StockDef(
    id: 'autostation',
    name: '오토스테이션',
    sector: '무인 탑승장',
    capScale: 16.0,
    volatility: 0.0105,
    dividendRate: 0.11,
    order: 14,
  ),
  StockDef(
    id: 'skyloop',
    name: '스카이루프',
    sector: '고공 루프',
    capScale: 16.5,
    volatility: 0.0120,
    dividendRate: 0.12,
    order: 15,
  ),
  StockDef(
    id: 'fantasyisland',
    name: '판타지아일랜드',
    sector: '테마 스킨',
    capScale: 17.0,
    volatility: 0.0180,
    dividendRate: 0.14,
    order: 16,
  ),
  StockDef(
    id: 'seouldreampark',
    name: '서울드림파크',
    sector: '최상위 파크 브랜드',
    capScale: 18.0,
    volatility: 0.0060,
    dividendRate: 0.08,
    order: 17,
  ),
];

/// Compute intrinsic price for a stock at its scale.
double intrinsicPriceFor(StockDef def) {
  // Each order step roughly multiplies price by capScale. We multiply each
  // tier's capScale together, then multiply by base.
  var price = basePricePerShare;
  for (final s in parkStockCatalog) {
    if (s.order >= def.order) break;
    price *= s.capScale;
  }
  // For the first stock the intrinsic is exactly base. For later stocks we
  // also multiply by the def's own capScale once to anchor it.
  if (def.order == 1) return price;
  return price * def.capScale;
}

StockDef? stockById(String id) {
  for (final s in parkStockCatalog) {
    if (s.id == id) return s;
  }
  return null;
}
