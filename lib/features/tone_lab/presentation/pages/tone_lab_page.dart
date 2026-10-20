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
      'title': '애인 공감 (사용자 예시)',
      'user_context': '오늘 애인이 내 말을 공감도 안 하고 평가하려들고 너무 짜증나!',
      'source_text': '공감을 안 해주고 많이 속상했겠어요',
      'style': ToneStyleType.warmFriend,
      'protected_facts': ['공감 안 해주고'],
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

  void _showEngineSettingsModal(BuildContext context) {
    final cubit = context.read<ToneLabCubit>();
    final state = cubit.state;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.tune, color: Color(0xFF283593)),
                  SizedBox(width: 8),
                  Text(
                    '추론 엔진 / 모델 선택',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '원하시는 추론 엔진을 탭하여 즉시 전환할 수 있습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),

              // Option 1: Pure Dart Engine
              _buildEngineOptionCard(
                context: context,
                mode: EngineMode.pureDart,
                currentMode: state.engineMode,
                title: '⚡ 순수 Dart 인앱 엔진 (Pure Dart)',
                badge: '모바일/시뮬레이터 최적',
                badgeColor: const Color(0xFF00796B),
                description: '외부 바이너리/서버 없이 100% Dart 코드로 인앱 구동됩니다. 지연시간 80ms, 수치·부정 표현 100% 보존.',
                specs: '속도: ~100ms | 용량: 0MB 추가 | 환경: iOS/Android/macOS',
                onSelect: () {
                  cubit.setEngineMode(EngineMode.pureDart);
                  Navigator.pop(bottomSheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⚡ 순수 Dart 인앱 엔진으로 전환되었습니다.')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Qwen3-0.6B GGUF Model
              _buildEngineOptionCard(
                context: context,
                mode: EngineMode.localGguf,
                currentMode: state.engineMode,
                title: '🧠 온디바이스 Qwen3-0.6B (GGUF Q4_K_M)',
                badge: state.isGgufModelReady ? '신경망 LLM (준비됨)' : '모델 파일 필요',
                badgeColor: state.isGgufModelReady ? const Color(0xFF283593) : Colors.grey,
                description: 'Qwen3 0.6B 실제 가중치 로컬 추론. Apple Silicon Metal GPU 가속 기반 초당 220+ 토큰 생성.',
                specs: '속도: ~1.3s (220 t/s) | 용량: ${state.modelFileSize} | 런타임: llama.cpp v0.7.0',
                enabled: true,
                onSelect: () {
                  cubit.setEngineMode(EngineMode.localGguf);
                  Navigator.pop(bottomSheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🧠 온디바이스 Qwen3-0.6B LLM으로 전환되었습니다.')),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Mock Simulator
              _buildEngineOptionCard(
                context: context,
                mode: EngineMode.mock,
                currentMode: state.engineMode,
                title: '🛠 Mock 모의 시뮬레이터',
                badge: '테스트용',
                badgeColor: Colors.orange.shade800,
                description: '오프라인 규칙 기반 간이 테스트 시뮬레이터 (isMock: true 명시).',
                specs: '속도: ~280ms | 용량: 0MB | 런타임: Mock Data',
                onSelect: () {
                  cubit.setEngineMode(EngineMode.mock);
                  Navigator.pop(bottomSheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🛠 Mock 모의 시뮬레이터로 전환되었습니다.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEngineOptionCard({
    required BuildContext context,
    required EngineMode mode,
    required EngineMode currentMode,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required String specs,
    required VoidCallback onSelect,
    bool enabled = true,
  }) {
    final isSelected = currentMode == mode;

    return InkWell(
      onTap: enabled ? onSelect : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.08) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? badgeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? badgeColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: enabled ? null : Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    specs,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              String shortLabel;
              Color chipColor;
              switch (state.engineMode) {
                case EngineMode.pureDart:
                  shortLabel = '⚡ 순수 Dart';
                  chipColor = const Color(0xFF00796B);
                  break;
                case EngineMode.localGguf:
                  shortLabel = '🧠 Qwen3 0.6B';
                  chipColor = const Color(0xFF283593);
                  break;
                case EngineMode.mock:
                  shortLabel = '🛠 Mock';
                  chipColor = Colors.orange.shade800;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: Text(
                    shortLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: chipColor),
                  ),
                  backgroundColor: chipColor.withValues(alpha: 0.12),
                  side: BorderSide(color: chipColor.withValues(alpha: 0.4)),
                  onPressed: () => _showEngineSettingsModal(context),
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
        subtitleText = '외부 바이너리/서버 없이 100% Dart 코드로 모바일 및 시뮬레이터에서 즉시 구동 (우측 상단 칩을 눌러 변경 가능)';
        break;
      case EngineMode.localGguf:
        bannerColor = const Color(0xFF283593);
        bannerIcon = Icons.memory;
        titleText = '온디바이스 LLM: Qwen3-0.6B-Q4_K_M (Apple Silicon Metal)';
        subtitleText = 'GGUF 가중치 (${state.modelFileSize}) 로컬 가속 추론 (우측 상단 칩을 눌러 변경 가능)';
        break;
      case EngineMode.mock:
        bannerColor = Colors.orange.shade800;
        bannerIcon = Icons.rule;
        titleText = '모의 서비스 (Mock Rule Simulator)';
        subtitleText = '오프라인 규칙 기반 간이 시뮬레이터 (isMock: true)';
        break;
    }

    return InkWell(
      onTap: () => _showEngineSettingsModal(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                  Row(
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bannerColor),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
                    ],
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
                hintText: '예: 오늘 애인이 내 말을 공감도 안 하고 평가하려들고 너무 짜증나!',
              ),
              onChanged: (val) => context.read<ToneLabCubit>().updateUserContext(val),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _sourceController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '서버 LLM 원본 응답 (필수)*',
                hintText: '예: 공감을 안 해주고 많이 속상했겠어요',
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
