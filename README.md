# 롤러코스터 키우기 (Roll Cliker)

> 검 키우기처럼 하나의 대상을 끝없이 성장시키되, 검 대신 허름한 롤러코스터 한 대를 키우는 파스텔 힐링 클리커 게임.

Flutter 3.5+ / Riverpod 기반 싱글-오브젝트 클리커 / 방치형 게임.

## 핵심 루프

```text
출발/응원 터치 → 탑승 수익 → 강화 → 자동 운행 수익 증가
              → 오프라인 보상 → 리뉴얼 오픈 → 명성 배율 → 더 빠른 성장
```

## 구현된 기능 (1차 출시 범위)

### 코어
- 50ms 틱 시뮬레이션
- 11종 출발/응원 강화 (`baseCost × 1.10^level`)
- 30종 자동 운영 요소 (`baseCost × 1.15^level`, Lv 25/50/100/200/500/1000 마일스톤)
- 7종 명성(리뉴얼) 강화
- 코스터 외형 10단계 (총 누적 코인 기반)
- 12시간 오프라인 보상 (효율 100%, 30초 미만 팝업 생략)
- 검키우기식 리뉴얼 — `floor(sqrt(totalCoin / 1e7) + ...)`

### 손맛
- 5% 크리티컬 ×10
- 1.5초 콤보 윈도우, 최대 50스택, 스택당 +1%
- 50 콤보 도달 시 60초치 코인 즉시 지급 (만석 대박 운행)
- 250탭마다 황금 손님 (HP 10, 처치 시 탭 ×5,000)

### 콘텐츠
- 7종 스킬 (터보 출발, 콤보 서지, 정수 모으기, 자동 출발, 골드러시, 만석 호출, 황금 소환)
- 3종 부스터 (CPS x2 30분 / 탭 x2 15분 / 러시 x3 5분)
- 8종 일일 미션, 8종 주간 미션
- 11종 업적 (정수 보상)
- 13종 코스터 부품 + 4종 세트 보너스 (소환, 천장 80회, 등급 N~UR)
- 환금소 8종 (CPS 시간치 환금 + 긴급 자금)

### 주식 시장 (1B 코인 누적 시 해금)
- 17종 파크 산업 종목
- 1초 가격 틱, 30초 캔들, 60개 보관
- 1시간마다 배당 누적
- 거래 수수료 2%, 보유 상한 80%, 다음 종목 해금 20%
- 가격은 내재가의 0.10배 ~ 18.5배 사이로 고정

### 파스텔 화면 (CustomPainter)
- 손님 줄서기 → 탑승 → 안전바 → 출발 → 운행 → 도착 → 하차 → 정산 사이클
- 코스터 외형이 단계마다 색깔/이펙트 변화
- 떠오르는 데미지 숫자, 토스트, 황금 손님 등장 애니메이션

## 실행

```bash
flutter pub get
flutter run -d windows   # 또는 chrome / android / ios
```

## 폴더 구조

```text
lib/
  main.dart
  app.dart
  core/        — theme, number_format
  models/      — save_data, coaster_upgrade, auto_producer, prestige_upgrade,
                 stock_market, coaster_part, booster, skill, mission, achievement
  data/        — 11/30/7/17/8/8/11종 카탈로그 + feature unlocks
  services/    — save_service (SharedPreferences)
  providers/   — game_provider (50ms 틱 + 게임 전체 상태)
  screens/     — main / home / upgrade / shop / prestige / stock_market
  widgets/     — coaster_scene, floating_number, golden_guest, toast_overlay,
                 stats_header, upgrade_tile, candle_chart, offline_reward_dialog
```

## 향후 추가 (Phase 5)

- 사운드 / 햅틱
- IAP (정수 패키지, 광고 제거, 시즌 패스)
- 보상형 광고 (오프라인 2배, 황금 손님 즉시 등장 등)
- 클라우드 저장 (Supabase 연동)
- 시즌 스킨 / 컷씬 / 명성 업적 계단
