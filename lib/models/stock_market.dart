class StockDef {
  final String id;
  final String name;
  final String sector;
  final double capScale;     // multiplier of base cap
  final double volatility;   // sigma per tick
  final double dividendRate; // hourly dividend fraction
  final int order;           // unlock order

  const StockDef({
    required this.id,
    required this.name,
    required this.sector,
    required this.capScale,
    required this.volatility,
    required this.dividendRate,
    required this.order,
  });
}

class Candle {
  double open;
  double high;
  double low;
  double close;
  DateTime startedAt;

  Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'startedAt': startedAt.toIso8601String(),
      };

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
        open: (json['open'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class StockState {
  String id;
  bool unlocked;
  int shares;
  double avgCost;
  double currentPrice;
  double intrinsicPrice;
  double pendingDividend;
  DateTime? lastAccrualAt;
  List<Candle> recentCandles;
  Candle? formingCandle;

  StockState({
    required this.id,
    this.unlocked = false,
    this.shares = 0,
    this.avgCost = 0,
    required this.currentPrice,
    required this.intrinsicPrice,
    this.pendingDividend = 0,
    this.lastAccrualAt,
    List<Candle>? recentCandles,
    this.formingCandle,
  }) : recentCandles = recentCandles ?? <Candle>[];

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'unlocked': unlocked,
        'shares': shares,
        'avgCost': avgCost,
        'currentPrice': currentPrice,
        'intrinsicPrice': intrinsicPrice,
        'pendingDividend': pendingDividend,
        'lastAccrualAt': lastAccrualAt?.toIso8601String(),
        'recentCandles': recentCandles.map((c) => c.toJson()).toList(),
        'formingCandle': formingCandle?.toJson(),
      };

  factory StockState.fromJson(Map<String, dynamic> json) => StockState(
        id: json['id'] as String,
        unlocked: json['unlocked'] as bool? ?? false,
        shares: json['shares'] as int? ?? 0,
        avgCost: (json['avgCost'] as num?)?.toDouble() ?? 0,
        currentPrice: (json['currentPrice'] as num).toDouble(),
        intrinsicPrice: (json['intrinsicPrice'] as num).toDouble(),
        pendingDividend: (json['pendingDividend'] as num?)?.toDouble() ?? 0,
        lastAccrualAt:
            DateTime.tryParse(json['lastAccrualAt'] as String? ?? ''),
        recentCandles: ((json['recentCandles'] as List?) ?? const [])
            .map((e) => Candle.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        formingCandle: json['formingCandle'] == null
            ? null
            : Candle.fromJson(
                Map<String, dynamic>.from(json['formingCandle'] as Map)),
      );
}

class StockMarketState {
  Map<String, StockState> stocks;
  int totalTrades;
  double totalFeesPaid;
  double totalDividendsClaimed;
  double totalRealizedProfit;

  StockMarketState({
    Map<String, StockState>? stocks,
    this.totalTrades = 0,
    this.totalFeesPaid = 0,
    this.totalDividendsClaimed = 0,
    this.totalRealizedProfit = 0,
  }) : stocks = stocks ?? <String, StockState>{};

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stocks': stocks.map((k, v) => MapEntry(k, v.toJson())),
        'totalTrades': totalTrades,
        'totalFeesPaid': totalFeesPaid,
        'totalDividendsClaimed': totalDividendsClaimed,
        'totalRealizedProfit': totalRealizedProfit,
      };

  factory StockMarketState.fromJson(Map<String, dynamic> json) {
    final raw = (json['stocks'] as Map?) ?? const <String, dynamic>{};
    final parsed = <String, StockState>{};
    raw.forEach((k, v) {
      parsed[k as String] =
          StockState.fromJson(Map<String, dynamic>.from(v as Map));
    });
    return StockMarketState(
      stocks: parsed,
      totalTrades: json['totalTrades'] as int? ?? 0,
      totalFeesPaid: (json['totalFeesPaid'] as num?)?.toDouble() ?? 0,
      totalDividendsClaimed:
          (json['totalDividendsClaimed'] as num?)?.toDouble() ?? 0,
      totalRealizedProfit:
          (json['totalRealizedProfit'] as num?)?.toDouble() ?? 0,
    );
  }
}
