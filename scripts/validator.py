"""
Static Fact Preservation and Anomaly Validator for Korean Tone Rewriter.
"""
import re
from typing import Dict, Any, List

class FactPreservationValidator:
    def __init__(self):
        # Numbers regex (e.g. 10월, 23일, 3시, 6,000원, 22도 등)
        self.num_pattern = re.compile(r'\d+(?:[.,]\d+)?(?:월|일|시|분|초|도|원|명|회|개|층|번|잔|권)?')
        # Negation keywords in Korean
        self.negation_patterns = [
            r'않(?:다|아|았|은|을|으면|고)',
            r'없(?:다|어|었|는|을|으면|고)',
            r'못(?:했|하|할|한)',
            r'금지',
            r'아니(?:다|라|며|면|었)',
            r'불가',
            r'절대',
            r'미만',
            r'미흡'
        ]

    def validate(self, source_text: str, rewritten_text: str, protected_facts: List[str] = None) -> Dict[str, Any]:
        flags = []
        is_valid = True
        
        # 1. Anomaly Check: Empty string
        if not rewritten_text or not rewritten_text.strip():
            return {
                "is_valid": False,
                "flags": ["EMPTY_OUTPUT"],
                "reason": "출력 결과가 비어 있습니다."
            }

        # 2. Anomaly Check: <think> leaks or prompt echoes
        if "<think>" in rewritten_text or "</think>" in rewritten_text:
            flags.append("THINK_TAG_LEAK")
            is_valid = False
            
        if "<|im_start|>" in rewritten_text or "<|im_end|>" in rewritten_text:
            flags.append("TEMPLATE_TOKEN_LEAK")
            is_valid = False

        # 3. Anomaly Check: Excessive repetition
        words = rewritten_text.split()
        if len(words) > 8:
            for w in set(words):
                if words.count(w) > len(words) * 0.4:
                    flags.append("EXTREME_REPETITION")
                    is_valid = False
                    break

        # 4. Anomaly Check: Non-Korean intrusion (Chinese / excessive English)
        chinese_chars = re.findall(r'[\u4e00-\u9fff]', rewritten_text)
        if len(chinese_chars) > 2:
            flags.append("CHINESE_CHAR_INTRUSION")
            is_valid = False

        # 5. Protected Facts Check
        if protected_facts:
            for fact in protected_facts:
                # Basic sub-word or token matching
                fact_tokens = re.findall(r'\w+', fact)
                found = any(tok in rewritten_text for tok in fact_tokens if len(tok) >= 2)
                if not found and any(c.isdigit() for c in fact):
                    # Strict for numeric facts
                    flags.append(f"MISSING_PROTECTED_FACT({fact})")
                    is_valid = False

        # 6. Question Polarity Check: If source has question, rewritten should likely preserve question intent
        source_is_question = "?" in source_text or any(source_text.endswith(end) for end in ["나요", "가요", "까", "니", "냐"])
        rewritten_is_question = "?" in rewritten_text or any(rewritten_text.endswith(end) for end in ["냐", "니", "까", "나", "어?", "가?"])
        if source_is_question and not rewritten_is_question:
            flags.append("QUESTION_INTENT_DROPPED")
            # Soft violation (warning) or strict depending on case

        # 7. Negation Polarity Check
        source_has_negation = any(re.search(pat, source_text) for pat in self.negation_patterns)
        rewritten_has_negation = any(re.search(pat, rewritten_text) for pat in self.negation_patterns)
        if source_has_negation and not rewritten_has_negation:
            flags.append("NEGATION_POLARITY_INVERTED")
            is_valid = False

        return {
            "is_valid": is_valid,
            "flags": flags,
            "reason": "; ".join(flags) if flags else "OK"
        }
