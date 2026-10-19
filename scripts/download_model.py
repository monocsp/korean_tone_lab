"""
Script to download Qwen3-0.6B Q4_K_M GGUF model into models/ directory.
Verifies file size and downloads only if missing or incomplete.
"""
import os
import sys
from huggingface_hub import hf_hub_download

REPO_ID = "bartowski/Qwen_Qwen3-0.6B-GGUF"
FILENAME = "Qwen_Qwen3-0.6B-Q4_K_M.gguf"
TARGET_DIR = os.path.abspath("models")
EXPECTED_SIZE = 484220320  # ~461.79 MB

def download_model(force: bool = False):
    os.makedirs(TARGET_DIR, exist_ok=True)
    target_path = os.path.join(TARGET_DIR, FILENAME)
    
    if os.path.exists(target_path) and not force:
        size = os.path.getsize(target_path)
        if size == EXPECTED_SIZE:
            print(f"Model already exists at {target_path} (Size: {size:,} bytes). Skipping download.")
            return target_path
        else:
            print(f"Existing file size mismatch ({size} != {EXPECTED_SIZE}). Re-downloading...")
            
    print(f"Starting download from {REPO_ID}/{FILENAME}...")
    print(f"Target path: {target_path}")
    downloaded_path = hf_hub_download(
        repo_id=REPO_ID,
        filename=FILENAME,
        local_dir=TARGET_DIR,
        local_dir_use_symlinks=False
    )
    final_size = os.path.getsize(target_path)
    print(f"Download complete! Final size: {final_size:,} bytes.")
    return target_path

if __name__ == "__main__":
    force_flag = "--force" in sys.argv
    download_model(force=force_flag)
