import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/tone_style.dart';
import '../cubit/tone_lab_cubit.dart';
import '../cubit/tone_lab_state.dart';

class ToneLabPage extends StatefulWidget {
  const ToneLabPage({super.key});

  @override
  State<ToneLabPage> createState() => _ToneLabPageState();
}

class _ToneLabPageState extends State<ToneLabPage> {
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();

  final List<Map<String, dynamic>> _samplePresets = [
    {
      'title': '날씨 안내 (수치 보존)',
      'user_context': '오늘 날씨 진짜 좋다 그치?',
      'source_text': '네, 맞습니다. 오늘 기온은 약 22도로 매우 온화한 날씨 패턴을 보이고 있습니다. 야외 활동을 하기에 아주 적합한 날씨로 판단됩니다.',
      'style': ToneStyleType.warmFriend,
      'protected_facts': ['22도', '야외 활동'],
    },
    {
      'title': '회의 일정 (지시서 필수 1)',
      'user_context': '회의 일정 다시 확인해줘',
      'source_text': '회의는 10월 23일 오후 3시이며, 2층 회의실입니다.',
      'style': ToneStyleType.naturalKorean,
      'protected_facts': ['10월 23일', '오후 3시', '2층 회의실'],
    },
    {
      'title': '연락 여부 부정 (지시서 필수 2)',
      'user_context': '오늘 꼭 전화해야 해?',
      'source_text': '오늘은 연락하지 않아도 괜찮아.',
      'style': ToneStyleType.warmFriend,
      'protected_facts': ['연락하지 않아도 됨'],
    },
    {
      'title': '확신 부정 (지시서 필수 3)',
      'user_context': '걔가 진짜 범인이야?',
      'source_text': '그 사람이 그랬다고 확신할 수는 없습니다.',
      'style': ToneStyleType.naturalKorean,
      'protected_facts': ['확신할 수 없음'],
    },
    {
      'title': '의문형 유지 (지시서 필수 4)',
      'user_context': '표정이 왜 그래?',
      'source_text': '어떤 일이 있었나요?',
      'style': ToneStyleType.warmFriend,
      'protected_facts': ['어떤 일인지 질문'],
    },
    {
      'title': '회사 질책 공감',
      'user_context': '오늘 회사에서 상사한테 엄청 깨졌어... 너무 속상해',
      'source_text': '상사로부터의 질책으로 인해 귀하께서 경험하고 계신 부정적인 정서와 좌절감에 심심한 위로를 전달합니다. 귀하의 역량이 부족해서가 아니니 자책을 금하시기 바랍니다.',
      'style': ToneStyleType.warmFriend,
      'protected_facts': ['상사 질책', '자책 금지'],
    },
    {
      'title': '메뉴 선택 (장난스러운 친구)',
      'user_context': '점심 뭐 먹을지 아직 못 정했어',
      'source_text': '점심 메뉴를 선택하는 것에 있어 고민이 되신다면, 따뜻한 김치찌개 혹은 가벼운 샌드위치를 고려해보시는 것은 어떨까요?',
      'style': ToneStyleType.playfulFriend,
      'protected_facts': ['김치찌개', '샌드위치'],
    },
  ];

  @override
  void dispose() {
    _contextController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    _contextController.text = preset['user_context'] as String;
    _sourceController.text = preset['source_text'] as String;
    context.read<ToneLabCubit>().loadSample(
      userContext: preset['user_context'] as String,
      sourceText: preset['source_text'] as String,
      style: preset['style'] as ToneStyleType,
      protectedFacts: List<String>.from(preset['protected_facts'] as List),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 22),
            SizedBox(width: 8),
            Text('Korean Tone Lab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          BlocBuilder<ToneLabCubit, ToneLabState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EngineMode>(
                    value: state.engineMode,
                    dropdownColor: Theme.of(context).cardColor,
                    icon: const Icon(Icons.tune, size: 18),
                    items: [
                      const DropdownMenuItem(
                        value: EngineMode.pureDart,
                        child: Text('⚡ 순수 Dart 엔진', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      DropdownMenuItem(
                        value: EngineMode.localGguf,
                        enabled: state.isGgufModelReady,
                        child: Text(
                          state.isGgufModelReady ? '🧠 Qwen3 GGUF (Metal)' : '🧠 Qwen3 GGUF (미설치)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: state.isGgufModelReady ? null : Colors.grey,
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: EngineMode.mock,
                        child: Text('🛠 Mock 모의 엔진', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        context.read<ToneLabCubit>().setEngineMode(mode);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ToneLabCubit, ToneLabState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEngineStatusBar(state),
                    const SizedBox(height: 14),
                    _buildPresetSelector(state),
                    const SizedBox(height: 18),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildInputCard(state)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildComparisonCard(state)),
                        ],
                      )
                    else ...[
                      _buildInputCard(state),
                      const SizedBox(height: 16),
                      _buildComparisonCard(state),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEngineStatusBar(ToneLabState state) {
    Color bannerColor;
    IconData bannerIcon;
    String titleText;
    String subtitleText;

    switch (state.engineMode) {
      case EngineMode.pureDart:
        bannerColor = const Color(0xFF00796B);
        bannerIcon = Icons.bolt;
        titleText = '순수 Dart 인앱 엔진 (Pure Dart NLP Engine)';
        subtitleText = '외부 바이너리/서버 없이 100% Dart 코드로 모바일 및 시뮬레이터에서 즉시 구동';
        break;
      case EngineMode.localGguf:
        bannerColor = const Color(0xFF283593);
        bannerIcon = Icons.memory;
        titleText = '온디바이스 LLM: Qwen3-0.6B-Q4_K_M (Apple Silicon Metal)';
        subtitleText = 'GGUF 가중치 (${state.modelFileSize}) 로컬 가속 추론 (초당 ~220 토큰)';
        break;
      case EngineMode.mock:
        bannerColor = Colors.orange.shade800;
        bannerIcon = Icons.rule;
        titleText = '모의 서비스 (Mock Rule Simulator)';
        subtitleText = '오프라인 규칙 기반 간이 시뮬레이터 (isMock: true)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bannerColor),
                ),
                Text(
                  subtitleText,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(ToneLabState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('빠른 샘플 불러오기 (대표 케이스):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _samplePresets.map((preset) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(Icons.bookmark_border, size: 15),
                  label: Text(preset['title'] as String, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _applyPreset(preset),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(ToneLabState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. 입력 정보 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Divider(height: 20),
            TextField(
              controller: _contextController,
              decoration: const InputDecoration(
                labelText: '직전 사용자 발화 (맥락, 선택)',
                hintText: '예: 오늘 날씨 진짜 좋다 그치?',
              ),
              onChanged: (val) => context.read<ToneLabCubit>().updateUserContext(val),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _sourceController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '서버 LLM 원본 응답 (필수)*',
                hintText: '변환할 딱딱하거나 번역투의 원문 텍스트를 입력하세요.',
              ),
              onChanged: (val) => context.read<ToneLabCubit>().updateSourceText(val),
            ),
            const SizedBox(height: 18),
            const Text('2. 목표 스타일 선택', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ToneStyleType.values.map((style) {
                final isSelected = state.selectedStyle == style;
                return ChoiceChip(
                  label: Text(style.displayName, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<ToneLabCubit>().setStyle(style);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              state.selectedStyle.description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF283593),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: state.status == ToneLabStatus.loading
                  ? null
                  : () => context.read<ToneLabCubit>().rewrite(),
              icon: state.status == ToneLabStatus.loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.bolt, size: 20),
              label: Text(
                state.status == ToneLabStatus.loading ? '말투 변환 수행 중...' : '온디바이스 말투 변환 실행',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(ToneLabState state) {
    final result = state.result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('3. 원문 vs 변환문 나란히 비교', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (result != null)
                  IconButton(
                    tooltip: '변환문 복사',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.rewrittenText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('클립보드에 복사되었습니다!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
              ],
            ),
            const Divider(height: 20),
            if (result == null)
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  '좌측에서 텍스트를 입력하고\n[온디바이스 말투 변환 실행]을 눌러주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 15),
                    label: Text('${result.latencyMs} ms', style: const TextStyle(fontSize: 12)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.speed, size: 15),
                    label: Text('${result.tokensPerSec.toStringAsFixed(1)} t/s', style: const TextStyle(fontSize: 12)),
                  ),
                  if (result.usedFallback)
                    const Chip(
                      backgroundColor: Color(0xFFFFEBEE),
                      avatar: Icon(Icons.shield_outlined, color: Colors.red, size: 15),
                      label: Text('Fallback 발동 (원문 유지)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  else
                    const Chip(
                      backgroundColor: Color(0xFFE8F5E9),
                      avatar: Icon(Icons.verified_outlined, color: Colors.green, size: 15),
                      label: Text('사실 보존 검증 통과', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
              if (result.usedFallback && result.fallbackReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fallback 사유: ${result.fallbackReason}',
                          style: const TextStyle(fontSize: 11, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              const Text('서버 원본 응답 (T0 기준선):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(state.sourceText, style: const TextStyle(fontSize: 13, height: 1.4)),
              ),
              const SizedBox(height: 14),
              Text(
                '온디바이스 변환 결과 (${state.selectedStyle.displayName}):',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF283593)),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3F51B5).withValues(alpha: 0.3)),
                ),
                child: Text(
                  result.rewrittenText,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
