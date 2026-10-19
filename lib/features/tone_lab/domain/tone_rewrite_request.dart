import 'tone_style.dart';

/// Request object containing input text, context, and rewrite parameters.
class ToneRewriteRequest {
  final String sourceText;
  final String userContext;
  final ToneStyleType style;
  final List<String> protectedFacts;

  const ToneRewriteRequest({
    required this.sourceText,
    this.userContext = '',
    required this.style,
    this.protectedFacts = const [],
  });

  ToneRewriteRequest copyWith({
    String? sourceText,
    String? userContext,
    ToneStyleType? style,
    List<String>? protectedFacts,
  }) {
    return ToneRewriteRequest(
      sourceText: sourceText ?? this.sourceText,
      userContext: userContext ?? this.userContext,
      style: style ?? this.style,
      protectedFacts: protectedFacts ?? this.protectedFacts,
    );
  }
}
