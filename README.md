# Korean Tone Lab (온디바이스 한국어 자연화 & 캐릭터 말투 변환 PoC)

[![GitHub repo](https://img.shields.io/badge/GitHub-monocsp%2Fkorean__tone__lab-blue?logo=github)](https://github.com/monocsp/korean_tone_lab)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.0-0175C2?logo=dart)](https://dart.dev)
[![Model](https://img.shields.io/badge/Model-Qwen3--0.6B--Q4__K__M-orange?logo=huggingface)](https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF)
[![License](https://img.shields.io/badge/License-Apache--2.0-green)](LICENSE)

서버 LLM이 생성한 한국어 답변의 **사실·수치·부정·질문 의도를 100% 보존**하면서, 기기 내부의 경량 언어 모델 1개(Qwen3-0.6B Q4_K_M GGUF)를 활용해 **(A) 어색한 번역투 윤문**과 **(B) 지정된 캐릭터 말투(다정한 친구, 장난스러운 친구 등)** 로 실시간 재작성하는 온디바이스 Flutter PoC 애플리케이션입니다.

---

## 🚀 주요 특징

1. **초경량 온디바이스 추론:**
   - `Qwen/Qwen3-0.6B`의 GGUF 양자화 모델(`Q4_K_M`, 461.79 MB) 활용.
   - Apple Silicon Metal 가속 기반 **초당 220+ 토큰 생성, p50 지연시간 1.3초** 달성.
   - 서버 API 호출 추가 비용 0원, 사용자 기기 내부 완결형 처리.
2. **엄격한 사실 보존 & 안전 Fallback:**
   - 정적 검사기(`FactPreservationValidator`) 탑재.
   - 숫자, 날짜, 시간, 고유명사 누락 또는 부정 표현 왜곡 탐지 시 **즉시 서버 원문으로 안전 Fallback(보존율 100%)**.
3. **Flutter Clean & Bloc/Cubit 아키텍처:**
   - Domain / Data / Presentation 계층 분리.
   - Mock 시뮬레이터와 실제 온디바이스 추론 엔진의 명확한 상태 분리 및 UI 뱃지 표기.
   - 원본 vs 변환문 실시간 Side-by-side 비교 뷰 제공.
4. **체계적인 브랜치 기반 작업:**
   - GitHub `monocsp` 계정 연동 및 기능별 브랜치(`feat/...`) 단위 커밋/푸시/머지 워크플로우 준수.

---

## 📊 100개 벤치마크 실측 요약

자체 구축한 5개 범주 100개 평가셋(`datasets/eval_cases.jsonl`) 전수 실측 결과:

| 메트릭 | 실측 수치 | 비고 |
| :--- | :--- | :--- |
| **p50 지연시간 (Latency)** | **1,308.7 ms** | 약 1.3초 (실시간 대화 UX에 적합) |
| **p95 지연시간 (Latency)** | **1,458.9 ms** | 1.5초 이내 안정적 응답 |
| **평균 토큰 생성 속도** | **220.1 tokens/sec** | Apple Silicon Metal GPU 가속 |
| **정적 검증 통과율** | **91.0% (91 / 100)** | 수치, 날짜, 부정 표현 완벽 보존 |
| **안전 Fallback 발동률** | **9.0% (9 / 100)** | 위험 사례 적발 시 원문 복원 |
| **`<think>` 태그 누출** | **0 건 (0.0%)** | Non-thinking 모드 완벽 제어 |

---

## 🛠 아키텍처 개요

```text
korean_tone_lab/
├── lib/
│   ├── main.dart                                    # 앱 진입점 및 BlocProvider 주입
│   ├── core/
│   │   ├── model_manager.dart                      # 로컬 GGUF 모델 캐시/가용성 관리
│   │   └── theme/app_theme.dart                    # Material 3 테마 시스템
│   └── features/tone_lab/
│       ├── domain/                                 # 순수 비즈니스 엔티티 & 서비스 계약
│       │   ├── tone_style.dart                     # 지원 스타일 (natural_korean, warm_friend, playful_friend)
│       │   ├── tone_rewrite_request.dart           # 입력 요청 DTO
│       │   ├── tone_rewrite_result.dart            # 변환 결과, 지연시간, 메트릭 DTO
│       │   └── tone_rewrite_service.dart           # 추상 서비스 인터페이스
│       ├── data/                                   # 인프라 및 추론 구현체
│       │   ├── fact_preservation_validator.dart    # 숫자/날짜/부정/질문 정적 검사기
│       │   ├── local_tone_rewrite_service.dart     # llama.cpp 네이티브 바인딩 및 Fallback
│       │   └── mock_tone_rewrite_service.dart      # 오프라인 규칙 기반 모의 엔진
│       └── presentation/
│           ├── cubit/                              # Bloc/Cubit 상태 관리
│           └── pages/tone_lab_page.dart            # 비교 뷰, 프리셋, 텔레메트리 UI
├── assets/styles/                                  # 스타일별 프롬프트 가이드라인 (JSON)
├── datasets/eval_cases.jsonl                       # 100개 한국어 평가 벤치마크 케이스
├── scripts/
│   ├── download_model.py                           # Qwen3-0.6B Q4_K_M 자동 다운로드 스크립트
│   ├── prompt_builder.py                           # Non-thinking 프롬프트 포매터
│   ├── smoke_test.py                               # 10개 문장 스모크 테스트 실행기
│   ├── run_eval.py                                 # 100개 문장 전수 벤치마크 러너
│   └── validator.py                                # 파이썬 정적 검사기
├── results/                                        # 실측 벤치마크 결과 (CSV, JSONL)
├── test/                                           # 유닛 및 위젯 테스트 (14개 통과)
└── docs/                                           # 기술 보고서
    ├── source_verification.md                      # 10개 원문 대조 및 재검증 체크리스트
    ├── evaluation_report.md                        # T0~T4 상세 평가 보고서
    ├── decision.md                                 # 온디바이스 탑재 Go/No-Go 결정 메모
    └── follow_up_experiments.md                    # 한국어 문체 전용 LoRA SFT 로드맵
```

---

## 💻 빠른 시작 가이드

### 1. 사전 요구사항
- macOS (Apple Silicon 권장) 또는 Linux/Windows
- Flutter SDK `3.41.0+`, Dart SDK `3.11.0+`
- Python `3.10+` (huggingface_hub 패키지)
- `llama.cpp` CLI 도구 (macOS: `brew install llama.cpp`)

### 2. 저장소 복제 및 모델 다운로드
```bash
# 1) 저장소 클론
git clone https://github.com/monocsp/korean_tone_lab.git
cd korean_tone_lab

# 2) 모델 가중치 다운로드 (461.79 MB)
python3 scripts/download_model.py
```

### 3. PC 선행 평가 실행
```bash
# 스모크 테스트 (10개 케이스)
PYTHONPATH=. python3 scripts/smoke_test.py

# 전체 100개 벤치마크 실행
PYTHONPATH=. python3 scripts/run_eval.py
```

### 4. Flutter 앱 실행 및 테스트
```bash
# 의존성 설치
flutter pub get

# 정적 분석 및 테스트 실행 (14개 테스트 100% Pass)
flutter analyze
flutter test

# macOS 데스크톱에서 앱 실행
flutter run -d macos
```

---

## 🌿 Git 브랜치 전략

본 프로젝트는 `main` 브랜치 직접 푸시를 지양하고, 기능 단위 브랜치에서 작업/커밋/푸시 후 `main`에 병합하는 원칙을 따릅니다:

- `feat/project-setup`: Flutter 프로젝트 생성 및 GitHub public 연동
- `feat/dataset-and-styles`: 3가지 스타일 정의 및 100개 평가 데이터셋
- `feat/pc-baseline-eval`: PC 선행 실험 및 100개 케이스 전수 벤치마크
- `feat/flutter-core-and-tone-lab`: Flutter 도메인/데이터/UI 계층 및 14개 자동 테스트
- `feat/docs-and-verification`: 기술 검증서, 평가 보고서, 결정 메모, README

---

## 📜 라이선스

- **코드 및 앱:** Apache-2.0 License
- **기본 모델:** `Qwen/Qwen3-0.6B` (Apache-2.0)
- **평가 데이터셋:** `datasets/eval_cases.jsonl` (본 프로젝트 자체 구축, Apache-2.0 호환)
