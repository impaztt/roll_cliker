import 'package:flutter/material.dart';
import '../models/coaster_part.dart';

/// MVP gacha pool. Heavily weighted toward N/R; SR+ uses pity counter.
const coasterPartCatalog = <CoasterPartDef>[
  // ── Sweet 세트
  CoasterPartDef(
    id: 'sweet_train',
    name: '딸기 열차',
    setId: 'sweet',
    slot: PartSlot.train,
    rarity: PartRarity.r,
    icon: Icons.train,
    tapBonus: 0.02,
  ),
  CoasterPartDef(
    id: 'sweet_rail',
    name: '마카롱 레일',
    setId: 'sweet',
    slot: PartSlot.rail,
    rarity: PartRarity.r,
    icon: Icons.linear_scale,
    cpsBonus: 0.02,
  ),
  CoasterPartDef(
    id: 'sweet_station',
    name: '솜사탕 탑승장',
    setId: 'sweet',
    slot: PartSlot.station,
    rarity: PartRarity.sr,
    icon: Icons.cake,
    cpsBonus: 0.05,
  ),
  CoasterPartDef(
    id: 'sweet_staff',
    name: '핑크 진행요원',
    setId: 'sweet',
    slot: PartSlot.staff,
    rarity: PartRarity.r,
    icon: Icons.person_outline,
    tapBonus: 0.03,
  ),
  // ── Neon 세트
  CoasterPartDef(
    id: 'neon_train',
    name: '네온 열차',
    setId: 'neon',
    slot: PartSlot.train,
    rarity: PartRarity.sr,
    icon: Icons.train,
    cpsBonus: 0.04,
  ),
  CoasterPartDef(
    id: 'neon_rail',
    name: '네온 레일',
    setId: 'neon',
    slot: PartSlot.rail,
    rarity: PartRarity.sr,
    icon: Icons.bolt,
    cpsBonus: 0.04,
  ),
  CoasterPartDef(
    id: 'neon_effect',
    name: '네온 이펙트',
    setId: 'neon',
    slot: PartSlot.effect,
    rarity: PartRarity.ssr,
    icon: Icons.auto_awesome,
    cpsBonus: 0.08,
    goldenChanceBonus: 0.03,
  ),
  // ── Royal 세트
  CoasterPartDef(
    id: 'royal_train',
    name: '왕실 열차',
    setId: 'royal',
    slot: PartSlot.train,
    rarity: PartRarity.ssr,
    icon: Icons.directions_railway,
    tapBonus: 0.10,
  ),
  CoasterPartDef(
    id: 'royal_guest',
    name: 'VIP 손님 카드',
    setId: 'royal',
    slot: PartSlot.guest,
    rarity: PartRarity.lr,
    icon: Icons.star,
    tapBonus: 0.15,
    cpsBonus: 0.10,
  ),
  CoasterPartDef(
    id: 'origin_legendary',
    name: '근원 코스터',
    setId: 'origin',
    slot: PartSlot.train,
    rarity: PartRarity.ur,
    icon: Icons.diamond,
    tapBonus: 0.30,
    cpsBonus: 0.30,
    goldenChanceBonus: 0.05,
  ),
  // Fillers
  CoasterPartDef(
    id: 'basic_horn',
    name: '기본 경적',
    setId: 'basic',
    slot: PartSlot.staff,
    rarity: PartRarity.n,
    icon: Icons.notifications,
  ),
  CoasterPartDef(
    id: 'basic_seat',
    name: '기본 좌석',
    setId: 'basic',
    slot: PartSlot.train,
    rarity: PartRarity.n,
    icon: Icons.event_seat,
  ),
  CoasterPartDef(
    id: 'basic_flag',
    name: '대기열 깃발',
    setId: 'basic',
    slot: PartSlot.station,
    rarity: PartRarity.n,
    icon: Icons.flag,
  ),
];

const coasterSetCatalog = <CoasterSetDef>[
  CoasterSetDef(
    id: 'sweet',
    name: '스위트 코스터',
    accent: Color(0xFFF8BBD0),
    partIds: ['sweet_train', 'sweet_rail', 'sweet_station', 'sweet_staff'],
    tapBonus: {2: 0.05, 3: 0.05},
    cpsBonus: {3: 0.08, 4: 0.07},
    overallBonus: {4: 0.15},
  ),
  CoasterSetDef(
    id: 'neon',
    name: '네온 코스터',
    accent: Color(0xFF80DEEA),
    partIds: ['neon_train', 'neon_rail', 'neon_effect'],
    cpsBonus: {2: 0.06, 3: 0.10},
    overallBonus: {3: 0.10},
  ),
  CoasterSetDef(
    id: 'royal',
    name: '왕실 코스터',
    accent: Color(0xFFFFD54F),
    partIds: ['royal_train', 'royal_guest'],
    overallBonus: {2: 0.20},
  ),
  CoasterSetDef(
    id: 'origin',
    name: '근원 코스터',
    accent: Color(0xFFEC407A),
    partIds: ['origin_legendary'],
    overallBonus: {1: 0.25},
  ),
];

CoasterPartDef? partById(String id) {
  for (final p in coasterPartCatalog) {
    if (p.id == id) return p;
  }
  return null;
}

CoasterSetDef? setById(String id) {
  for (final s in coasterSetCatalog) {
    if (s.id == id) return s;
  }
  return null;
}
