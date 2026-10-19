# 후속 실험 제안서: 한국어 문체 전용 LoRA SFT 파이프라인

- **목적:** Qwen3-0.6B의 한국어 zero-shot 문체 전환 한계 극복 및 사실 보존율 98%+ 달성
- **접근 방식:** Parameter-Efficient Fine-Tuning (PEFT) LoRA + Hugging Face TRL `SFTTrainer`

---

## 1. 데이터셋 구축 전략

### 1.1 데이터 소스 및 라이선스 준수
- **SmileStyle 데이터셋 주의:** Smilegate SmileStyle(17개 문체)은 **CC BY-NC 4.0** 라이선스로 상업적 이용이 불가하며 자체 오탈자/스타일 오류가 보고되어 있음. 따라서 **직접 제작한 고품질 골든 데이터셋**을 사용하거나 사내 검수를 거쳐야 함.
- **초기 규모:** 300 ~ 500개 검수 문장 쌍 (`datasets/train_pairs.jsonl`).
- **스키마:**
  ```json
  {
    "user_context": "오늘 날씨 어때?",
    "source_text": "네, 맞습니다. 오늘 기온은 약 22도로 매우 온화합니다.",
    "target_style": "warm_friend",
    "target_text": "오늘 22도라 진짜 따뜻하고 좋아! 밖에서 산책하기 딱이야."
  }
  ```

---

## 2. LoRA 파인튜닝 파이프라인

### 2.1 학습 파라미터 (제안)
- **Base Model:** `Qwen/Qwen3-0.6B`
- **LoRA Config:**
  - `r = 16`, `lora_alpha = 32`, `lora_dropout = 0.05`
  - `target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]`
- **Training Config:**
  - `learning_rate = 2e-4` (Cosine schedule)
  - `batch_size = 4`, `gradient_accumulation_steps = 4`
  - `num_epochs = 3`
  - Mixed precision: `bf16` / `fp16`

### 2.2 어댑터 병합 및 GGUF 양자화
1. Base 가중치에 LoRA 어댑터 병합:
   ```python
   model = model.merge_and_unload()
   model.save_pretrained("./qwen3-0.6b-korean-tone")
   ```
2. `llama.cpp`의 `convert_hf_to_gguf.py`를 통해 GGUF 변환:
   ```bash
   python3 convert_hf_to_gguf.py ./qwen3-0.6b-korean-tone --outtype f16
   ```
3. Q4_K_M 양자화 수행:
   ```bash
   llama-quantize ./qwen3-0.6b-korean-tone-f16.gguf ./qwen3-0.6b-korean-tone-q4_k_m.gguf Q4_K_M
   ```

---

## 3. 대체 후보 모델 비교 검토

| 모델 후보 | 파라미터 | 장점 | 단점 및 모바일 제약 |
| :--- | :--- | :--- | :--- |
| **Qwen3-0.6B (현재)** | 0.6B (~461MB Q4) | Metal 기준 220 t/s, 1.3초 초고속, RAM 1.1GB 소모 | 순수 한국어 문체 다양성 및 지시 추종력 중간 |
| **Qwen2.5-1.5B-Instruct** | 1.5B (~1.0GB Q4) | 한국어 문법 및 사실 보존력 현저히 우수 | 파일 크기 1GB, 지연시간 ~2.5초로 증가, 저사양 기기 부담 |
| **Bllossom (Llama-3-8B)** | 8.0B (~4.5GB Q4) | 한국어 자연화 최상급 품질 | 모바일 온디바이스 탑재 불가능 (RAM 6GB+ 요구) |
| **한국어 특화 Seq2Seq (T5-small)** | ~60M (~120MB) | 초경량, 0.2초 초고속, 문체 변환 최적화 가능 | 긴 맥락 이해 및 다중 페르소나 처리 한계 |

**권고안:** 현재 `Qwen3-0.6B`의 1.3초 초고속 지연시간과 461MB 용량이 모바일 환경에 가장 최적이므로, 모델을 무작정 키우지 않고 **Qwen3-0.6B에 LoRA 어댑터를 학습시켜 탑재하는 전략이 가장 경제적이고 실현 가능성이 높음.**
