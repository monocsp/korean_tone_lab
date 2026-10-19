"""
Smoke test runner for Korean Tone Rewriting on Qwen3-0.6B-Q4_K_M GGUF.
Tests first 10 cases with target styles, records metrics, fact validator checks.
"""
import json
import os
import time
import subprocess
import re
from scripts.prompt_builder import load_style_config, build_rewrite_prompt
from scripts.validator import FactPreservationValidator

MODEL_PATH = "models/Qwen_Qwen3-0.6B-Q4_K_M.gguf"
DATASET_PATH = "datasets/eval_cases.jsonl"
OUTPUT_PATH = "results/smoke_results.jsonl"

def parse_llama_output(raw_stdout: str) -> tuple[str, float, float]:
    """
    Extracts the assistant response text and prompt/generation speeds.
    """
    prompt_speed = 0.0
    gen_speed = 0.0
    m_speed = re.search(r'\[ Prompt:\s+([\d.]+)\s+t/s\s+\|\s+Generation:\s+([\d.]+)\s+t/s \]', raw_stdout)
    if m_speed:
        prompt_speed = float(m_speed.group(1))
        gen_speed = float(m_speed.group(2))
        
    if '... (truncated)\n' in raw_stdout:
        generated = raw_stdout.split('... (truncated)\n', 1)[1]
    elif '> ' in raw_stdout:
        generated = raw_stdout.rsplit('> ', 1)[1]
    else:
        generated = raw_stdout
        
    generated = generated.split('[ Prompt:')[0]
    generated = generated.replace('Exiting...', '').strip()
    return generated, prompt_speed, gen_speed

def run_smoke_test(num_cases: int = 10):
    os.makedirs("results", exist_ok=True)
    validator = FactPreservationValidator()
    
    style_configs = {
        "natural_korean": load_style_config("assets/styles/natural_korean.json"),
        "warm_friend": load_style_config("assets/styles/warm_friend.json"),
        "playful_friend": load_style_config("assets/styles/playful_friend.json")
    }

    cases = []
    with open(DATASET_PATH, 'r', encoding='utf-8') as f:
        for idx, line in enumerate(f):
            if idx >= num_cases:
                break
            cases.append(json.loads(line))
            
    results = []
    print(f"Running smoke test on {len(cases)} cases...")
    
    for case in cases:
        case_id = case["id"]
        source_text = case["source_text"]
        user_context = case["user_context"]
        target_style = case["target_style"]
        protected_facts = case.get("protected_facts", [])
        
        style_cfg = style_configs.get(target_style, style_configs["natural_korean"])
        prompt = build_rewrite_prompt(user_context, source_text, style_cfg)
        
        cmd = [
            "llama-cli",
            "-m", MODEL_PATH,
            "--temp", "0.7",
            "--top-p", "0.8",
            "--top-k", "20",
            "--min-p", "0.0",
            "-n", "128",
            "--no-warmup",
            "--single-turn",
            "--reasoning", "off",
            "--reasoning-budget", "0",
            "--no-display-prompt",
            "--simple-io",
            "-p", prompt
        ]
        
        start_t = time.time()
        res = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
        latency_ms = (time.time() - start_t) * 1000.0
        
        output_text, prompt_speed, gen_speed = parse_llama_output(res.stdout)
        
        # Fallback check: If validation fails or empty, fallback to source_text
        val_res = validator.validate(source_text, output_text, protected_facts)
        used_fallback = False
        final_text = output_text
        if not val_res["is_valid"]:
            used_fallback = True
            final_text = source_text
        
        record = {
            "case_id": case_id,
            "category": case["category"],
            "model_id": "Qwen/Qwen3-0.6B",
            "quantization": "Q4_K_M (GGUF)",
            "prompt_version": "prompt_v1",
            "style_id": target_style,
            "seed_if_supported": None,
            "decode_params": {
                "temperature": 0.7,
                "top_p": 0.8,
                "top_k": 20,
                "min_p": 0.0,
                "max_tokens": 128
            },
            "device": "macOS Apple Silicon (Metal Accelerated)",
            "latency_ms": round(latency_ms, 2),
            "prompt_tokens_per_sec": prompt_speed,
            "gen_tokens_per_sec": gen_speed,
            "source_text": source_text,
            "raw_output": output_text,
            "final_text": final_text,
            "used_fallback": used_fallback,
            "fallback_reason": val_res["reason"] if used_fallback else None,
            "validator_flags": val_res["flags"],
            "validator_is_valid": val_res["is_valid"],
            "validator_reason": val_res["reason"],
            "human_scores": {
                "naturalness": None,
                "character_consistency": None,
                "fact_preservation": None,
                "status": "NOT_MEASURED"
            }
        }
        results.append(record)
        print(f"[{case_id}] style: {target_style} | latency: {latency_ms:.0f}ms | valid: {val_res['is_valid']} | fallback: {used_fallback}")
        print(f"  -> Out: {output_text}")

    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
            
    print(f"\nSmoke test complete! Saved {len(results)} results to {OUTPUT_PATH}")

if __name__ == "__main__":
    run_smoke_test(10)
