"""
Prompt Builder for Qwen3-0.6B Korean Tone Rewriter.
Follows non-thinking mode guidelines with strict fact-preservation constraints.
"""
import json
import os

def load_style_config(style_path: str) -> dict:
    with open(style_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def build_rewrite_prompt(user_context: str, source_text: str, style_config: dict) -> str:
    """
    Constructs the prompt for text-to-text tone rewriting.
    Uses Qwen3 non-thinking instruction format.
    """
    style_name = style_config.get("name", "")
    description = style_config.get("description", "")
    guidelines = "\n".join([f"- {g}" for g in style_config.get("guidelines", [])])
    constraints = "\n".join([f"- {c}" for c in style_config.get("constraints", [])])
    
    system_instruction = f"""너는 한국어 텍스트의 사실과 의미를 철저히 보존하면서 어색한 문장을 윤문하고 캐릭터 말투를 입히는 전문 재작성 엔진이다.
원문의 핵심 정보, 수치, 날짜, 고유명사, 부정 표현, 질문 의도는 절대 변경하거나 누락해서는 안 된다.
별도의 생각 과정(<think>)을 출력하지 말고 최종 변환된 한국어 문장만 즉시 출력하라.

[목표 스타일: {style_name}]
{description}

[스타일 작성 지침]
{guidelines}

[절대 제약사항 (위반 시 실패)]
{constraints}
"""

    user_content = f"""[직전 대화 맥락 (참고용)]
{user_context if user_context else "(없음)"}

[변환 대상 원문 (서버 응답)]
{source_text}

위 원문의 의미와 사실을 보존하면서 목표 스타일에 맞추어 변환된 문장만 출력해줘."""

    return f"<|im_start|>system\n{system_instruction}<|im_end|>\n<|im_start|>user\n{user_content}<|im_end|>\n<|im_start|>assistant\n"
