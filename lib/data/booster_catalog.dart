import '../models/booster.dart';

const boosterCatalog = <BoosterDef>[
  BoosterDef(
    id: 'cps_2x_30m',
    name: '자동 운행 x2',
    description: '30분간 CPS 2배',
    kind: BoosterKind.cps,
    multiplier: 2,
    duration: Duration(minutes: 30),
    essenceCost: 50,
  ),
  BoosterDef(
    id: 'tap_2x_15m',
    name: '응원 터치 x2',
    description: '15분간 탭 수익 2배',
    kind: BoosterKind.tap,
    multiplier: 2,
    duration: Duration(minutes: 15),
    essenceCost: 30,
  ),
  BoosterDef(
    id: 'rush_3x_5m',
    name: '코스터 러시 x3',
    description: '5분간 탭+CPS 3배',
    kind: BoosterKind.rush,
    multiplier: 3,
    duration: Duration(minutes: 5),
    essenceCost: 100,
  ),
];
