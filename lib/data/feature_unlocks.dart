enum FeatureGate {
  missions,
  summon,
  achievements,
  prestige,
  boosterShop,
  stockMarket,
  exchange,
}

class FeatureUnlock {
  final FeatureGate id;
  final String name;
  final String description;

  const FeatureUnlock({
    required this.id,
    required this.name,
    required this.description,
  });
}

const featureUnlocks = <FeatureUnlock>[
  FeatureUnlock(
    id: FeatureGate.missions,
    name: '미션',
    description: '일일/주간 미션을 클리어해 정수와 명성 보상을 획득',
  ),
  FeatureUnlock(
    id: FeatureGate.summon,
    name: '소환',
    description: '정수로 코스터 부품/스킨/손님 카드를 뽑는다',
  ),
  FeatureUnlock(
    id: FeatureGate.achievements,
    name: '업적',
    description: '업적을 달성해 정수를 모은다',
  ),
  FeatureUnlock(
    id: FeatureGate.prestige,
    name: '리뉴얼',
    description: '리뉴얼 오픈으로 영구 명성 강화',
  ),
  FeatureUnlock(
    id: FeatureGate.boosterShop,
    name: '부스터 상점',
    description: '시간제 버프로 일시적 폭풍 성장',
  ),
  FeatureUnlock(
    id: FeatureGate.stockMarket,
    name: '주식 시장',
    description: '파크 산업 17개 종목에 투자',
  ),
  FeatureUnlock(
    id: FeatureGate.exchange,
    name: '환금소',
    description: '정수를 코인으로 즉시 환전',
  ),
];
