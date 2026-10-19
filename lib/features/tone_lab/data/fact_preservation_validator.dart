/// Validation result indicating whether the rewritten text preserves facts and lacks anomalies.
class ValidationResult {
  final bool isValid;
  final List<String> flags;
  final String reason;

  const ValidationResult({
    required this.isValid,
    required this.flags,
    required this.reason,
  });
}

/// Static validator for Korean facts, negation polarity, question intent, and output sanity.
class FactPreservationValidator {
  final List<RegExp> _negationPatterns = [
    RegExp(r'않(?:다|아|았|은|을|으면|고)'),
    RegExp(r'없(?:다|어|었|는|을|으면|고)'),
    RegExp(r'못(?:했|하|할|한)'),
    RegExp(r'금지'),
    RegExp(r'아니(?:다|라|며|면|었)'),
    RegExp(r'불가'),
    RegExp(r'절대'),
  ];

  ValidationResult validate(
    String sourceText,
    String rewrittenText, {
    List<String> protectedFacts = const [],
  }) {
    final flags = <String>[];
    bool isValid = true;

    // 1. Empty output check
    if (rewrittenText.trim().isEmpty) {
      return const ValidationResult(
        isValid: false,
        flags: ['EMPTY_OUTPUT'],
        reason: '변환 결과가 비어 있습니다.',
      );
    }

    // 2. Anomaly Check: <think> tags or prompt leakage
    if (rewrittenText.contains('<think>') || rewrittenText.contains('</think>')) {
      flags.add('THINK_TAG_LEAK');
      isValid = false;
    }
    if (rewrittenText.contains('<|im_start|>') || rewrittenText.contains('<|im_end|>')) {
      flags.add('TEMPLATE_TOKEN_LEAK');
      isValid = false;
    }

    // 3. Excessive repetition check
    final words = rewrittenText.split(RegExp(r'\s+'));
    if (words.length > 8) {
      final wordCounts = <String, int>{};
      for (final w in words) {
        wordCounts[w] = (wordCounts[w] ?? 0) + 1;
      }
      for (final count in wordCounts.values) {
        if (count > words.length * 0.4) {
          flags.add('EXTREME_REPETITION');
          isValid = false;
          break;
        }
      }
    }

    // 4. Protected Facts Check (numbers, key entities)
    for (final fact in protectedFacts) {
      final tokens = RegExp(r'\w+').allMatches(fact).map((m) => m.group(0)!).toList();
      final found = tokens.any((tok) => tok.length >= 2 && rewrittenText.contains(tok));
      if (!found && fact.contains(RegExp(r'\d'))) {
        flags.add('MISSING_PROTECTED_FACT($fact)');
        isValid = false;
      }
    }

    // 5. Negation polarity preservation
    final sourceHasNegation = _negationPatterns.any((pat) => pat.hasMatch(sourceText));
    final rewrittenHasNegation = _negationPatterns.any((pat) => pat.hasMatch(rewrittenText));
    if (sourceHasNegation && !rewrittenHasNegation) {
      flags.add('NEGATION_POLARITY_INVERTED');
      isValid = false;
    }

    // 6. Question intent check
    final sourceIsQuestion = sourceText.contains('?') ||
        sourceText.endsWith('나요') ||
        sourceText.endsWith('가요') ||
        sourceText.endsWith('까');
    final rewrittenIsQuestion = rewrittenText.contains('?') ||
        rewrittenText.endsWith('냐') ||
        rewrittenText.endsWith('니') ||
        rewrittenText.endsWith('까') ||
        rewrittenText.endsWith('어?') ||
        rewrittenText.endsWith('나?');
    if (sourceIsQuestion && !rewrittenIsQuestion) {
      flags.add('QUESTION_INTENT_DROPPED');
      // Warning flag
    }

    return ValidationResult(
      isValid: isValid,
      flags: flags,
      reason: flags.isEmpty ? 'OK' : flags.join('; '),
    );
  }
}
