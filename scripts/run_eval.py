"""
Batch Evaluation Runner for 100 Cases.
Runs Qwen3-0.6B Q4_K_M on datasets/eval_cases.jsonl.
Outputs results/eval_results_100.jsonl and results/benchmark.csv.
"""
import json
import os
import time
import subprocess
import csv
from scripts.prompt_builder import load_style_config, build_rewrite_prompt
from scripts.validator import FactPreservationValidator
from scripts.smoke_test import parse_llama_output, MODEL_PATH, DATASET_PATH

EVAL_JSONL_PATH = "results/eval_results_100.jsonl"
BENCHMARK_CSV_PATH = "results/benchmark.csv"

def run_full_eval():
    os.makedirs("results", exist_ok=True)
    validator = FactPreservationValidator()
    
    style_configs = {
        "natural_korean": load_style_config("assets/styles/natural_korean.json"),
        "warm_friend": load_style_config("assets/styles/warm_friend.json"),
        "playful_friend": load_style_config("assets/styles/playful_friend.json")
    }

    cases = []
    with open(DATASET_PATH, 'r', encoding='utf-8') as f:
        for line in f:
            cases.append(json.loads(line))
            
    print(f"Starting batch evaluation on all {len(cases)} cases...")
    results = []
    
    csv_rows = []
    
    for idx, case in enumerate(cases):
        case_id = case["id"]
        category = case["category"]
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
        
        val_res = validator.validate(source_text, output_text, protected_facts)
        used_fallback = not val_res["is_valid"]
        final_text = source_text if used_fallback else output_text
        
        record = {
            "case_id": case_id,
            "category": category,
            "model_id": "Qwen/Qwen3-0.6B",
            "quantization": "Q4_K_M (GGUF)",
            "prompt_version": "prompt_v1",
            "style_id": target_style,
            "device": "macOS Apple Silicon (Metal)",
            "latency_ms": round(latency_ms, 2),
            "prompt_tokens_per_sec": prompt_speed,
            "gen_tokens_per_sec": gen_speed,
            "source_text": source_text,
            "raw_output": output_text,
            "final_text": final_text,
            "used_fallback": used_fallback,
            "fallback_reason": val_res["reason"] if used_fallback else None,
            "validator_flags": val_res["flags"],
            "validator_is_valid": val_res["is_valid"]
        }
        results.append(record)
        
        csv_rows.append({
            "case_id": case_id,
            "category": category,
            "style": target_style,
            "latency_ms": round(latency_ms, 2),
            "prompt_tps": prompt_speed,
            "gen_tps": gen_speed,
            "valid": val_res["is_valid"],
            "fallback": used_fallback,
            "flags": "; ".join(val_res["flags"])
        })
        
        if (idx + 1) % 10 == 0:
            print(f"Progress: {idx + 1}/{len(cases)} ({((idx + 1)/len(cases))*100:.0f}%) | Latency: {latency_ms:.0f}ms")

    with open(EVAL_JSONL_PATH, 'w', encoding='utf-8') as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + '\n')
            
    with open(BENCHMARK_CSV_PATH, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=["case_id", "category", "style", "latency_ms", "prompt_tps", "gen_tps", "valid", "fallback", "flags"])
        writer.writeheader()
        writer.writerows(csv_rows)
        
    print(f"\nFull evaluation complete! Saved results to {EVAL_JSONL_PATH} and {BENCHMARK_CSV_PATH}")

if __name__ == "__main__":
    run_full_eval()
