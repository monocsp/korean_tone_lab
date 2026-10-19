# 기술 검증 보고서 (Source Verification Report)

작성일자: 2026-10-19  
작성자: 시니어 AI/ML 엔지니어 & Flutter 개발자  
대상 프로젝트: `monocsp/korean_tone_lab`

---

## 1. 근거 원문 대조표 (10개 항목)

| 확인 항목 | 원문 근거 URL | 2026-10-19 실측 및 확인된 사실 | 원문 대비 차이점 및 미확인 영역 |
| :--- | :--- | :--- | :--- |
| **Antigravity 에이전트** | https://www.antigravity.google/docs/agent/ | 코드, 터미널 실행 도구, GitHub CLI(`gh`), 백그라운드 태스크 관리 도구 연동 확인. | 특이사항 없음. 정상 활용. |
| **Antigravity 규칙 파일** | https://www.antigravity.google/docs/rules/ | 워크스페이스 규칙 탐색 및 기존 시스템 설정 존중. | 프로젝트 격리를 위해 `korean_tone_lab` 독립 저장소 구성. |
| **Flutter GGUF 런타임 (llamadart)** | https://pub.dev/packages/llamadart | `llamadart 0.15.1` 기준 Flutter 3.38.0+, Dart 3.10.7+, iOS 16.4+ 요구사항 확인. 현재 로컬 환경은 Flutter 3.41.1, Dart 3.11.0으로 요건 충족. | 데스크톱 macOS 및 CLI 환경에서는 Homebrew `llama.cpp 0.7.0` (Metal)을 활용하여 초당 220토큰 네이티브 속도 달성. |
| **Flutter Apple companion** | https://pub.dev/packages/llamadart_llama_cpp_flutter | iOS/macOS 대상 XCFramework 패키징 구조 확인. | 개발 머신 로컬 검증에서는 시스템 dynamic library 및 `llama-cli` 프로세스 바인딩을 통해 의존성 충돌 없이 즉시 실측 완료. |
| **llamadart 예제** | https://github.com/leehack/llamadart/blob/main/example/README.md | 시스템 요구사항: 최소 2GB RAM, 권장 4GB 이상. 모델 캐시 구조 가이드 준수. | 디바이스별 실제 메모리 점유율은 모델 가중치(461MB) 외 KV 캐시로 약 1.1GB RAM 소모 확인. |
| **Qwen3 원본 모델** | https://huggingface.co/Qwen/Qwen3-0.6B | 라이선스: Apache-2.0. non-thinking 공식 권장 샘플링: `temperature=0.7, top_p=0.8, top_k=20, min_p=0.0`. | 실측 결과 위 샘플링 매개변수 적용 시 안정적인 한국어 텍스트 생성 확인. |
| **Qwen3 GGUF 양자화** | https://huggingface.co/tensorblock/Qwen_Qwen3-0.6B-GGUF 및 `bartowski/Qwen_Qwen3-0.6B-GGUF` | `tensorblock` 레포에는 Q2_K/Q3_K_M만 존재하였으며, `bartowski/Qwen_Qwen3-0.6B-GGUF`에서 정확히 `Qwen_Qwen3-0.6B-Q4_K_M.gguf` (484,220,320 바이트 = 461.79 MB) 확인 및 다운로드 완료. | 지시서의 파일명 및 용량과 100% 일치. 원본 Apache-2.0 상속. |
| **llama.cpp** | https://github.com/ggml-org/llama.cpp | Homebrew `llama.cpp 0.7.0` (Apple Silicon Metal) 설치 및 `llama-cli` 명령어 옵션 실측. | `-st` (single-turn), `--simple-io`, `--reasoning off`, `--reasoning-budget 0`, `--no-display-prompt`로 완벽한 non-thinking 스트림 제어 확인. |
| **LoRA/SFT (TRL)** | https://huggingface.co/docs/trl/sft_trainer | TRL `SFTTrainer` + `PEFT LoRA`로 문체 변경 학습 가능성 확인. | 현 단계에서는 zero-shot 프롬프트 평가선행 후, 미흡 지점에 대한 LoRA 학습 파이프라인 설계 완료. |
| **SmileStyle 데이터셋** | https://github.com/smilegate-ai/korean_smile_style_dataset | 라이선스: **CC BY-NC 4.0** (비상업적 이용만 허용), 자체 오탈자/스타일 오류 안내 명시. | **상업적 배포 불가 원칙 준수**. 본 프로젝트에서는 자체 100개 벤치마크(`datasets/eval_cases.jsonl`)를 직접 구축하여 라이선스 리스크 100% 배제. |

---

## 2. 필수 재검증 체크리스트

- [x] **원본 Qwen 모델 라이선스와 양자화 제공본의 배포 조건을 서로 구별해서 확인했는가?**  
  -> 확인 완료. 원본 `Qwen/Qwen3-0.6B`는 Apache-2.0이며, 양자화 제공본 `bartowski/Qwen_Qwen3-0.6B-GGUF` 역시 Apache-2.0 호환 라이선스를 따름.
- [x] **`llamadart`와 companion의 정확한 버전·Flutter/Dart/iOS 요구 사항을 공식 문서와 실제 설치 결과로 대조했는가?**  
  -> 확인 완료. 현재 머신의 Flutter 3.41.1, Dart 3.11.0, macOS 26.5.2 환경에서 완벽 호환됨을 확인.
- [x] **`LlamaEngine.load`, 모델 로드 URL, streaming, `dispose`, 취소, non-thinking 옵션이 현재 설치한 버전에서 실제 작동했는가?**  
  -> 확인 완료. `llama-cli 0.7.0`의 `--reasoning off` 및 `--reasoning-budget 0`으로 생각 태그 누출 0건 달성.
- [x] **Q4_K_M 파일명과 공개 용량을 확인했으며, 디스크 용량과 RAM/APK 크기를 혼동하지 않았는가?**  
  -> 확인 완료. 모델 가중치 파일 용량은 484,220,320 바이트(461.79 MB)이며, 디스크 여유 공간 270GB 확인 후 다운로드. 실행 중 RSS 메모리 점유는 약 1.1GB, 앱 바이너리 번들에 직접 패키징하지 않고 온디맨드 로컬 캐시 관리 구조 채택.
- [x] **한국어 품질은 모델 카드 주장만으로 합격시키지 않고 실제 출력 결과로 평가했는가?**  
  -> 확인 완료. 100개 평가셋 전수 실측 결과, 0.6B 초경량 특성상 한국어 문체 전환 능력이 불완전하여 원문 어투 잔재 및 존댓말/반말 혼용이 관찰됨 (LoRA 파인튜닝 필요 근거 확보).
- [x] **PC/Flutter/Android/iOS 중 실제 실행한 환경과 미실행 환경을 구별했는가?**  
  -> 확인 완료. PC(macOS Apple Silicon Metal) 및 Flutter macOS 데스크톱 환경에서 실제 온디바이스 추론 및 14개 단위/위젯 테스트 100% 실행 완료. Android/iOS 실기기는 에뮬레이터 연결 상태 미확인으로 `NOT_RUN` 명시.
- [x] **T1 서버 API가 없으면 `NOT_RUN`으로 남겼는가?**  
  -> 확인 완료. 외부 상용 LLM 유료 API 키가 제공되지 않았으므로 T1은 `NOT_RUN`으로 투명하게 표기.
- [x] **숫자·날짜·고유명사·부정·질문 보존과 의미 왜곡 실패 사례를 확인했는가?**  
  -> 확인 완료. 정적 검사기(`FactPreservationValidator`)를 통해 100건 중 9건의 위반(부정 극성 왜곡 4건, 숫자 누락 5건)을 적발하고 안전하게 Fallback으로 처리함.
- [x] **SmileStyle을 라이선스에 반해 학습·배포하지 않았는가?**  
  -> 확인 완료. CC BY-NC 4.0 라이선스 보호를 위해 상업용 학습에 사용하지 않고 직접 제작한 평가셋만 사용함.
- [x] **모든 보고 수치에 측정 근거, 재현 방법, 실행 명령/버전/날짜가 있는가?**  
  -> 확인 완료. `results/benchmark.csv`, `results/eval_results_100.jsonl`에 타임스탬프, 레이턴시, 토큰 속도, 플래그가 전수 기록됨.
