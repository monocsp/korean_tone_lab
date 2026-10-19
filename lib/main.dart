import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/model_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/tone_lab/data/local_tone_rewrite_service.dart';
import 'features/tone_lab/data/mock_tone_rewrite_service.dart';
import 'features/tone_lab/presentation/cubit/tone_lab_cubit.dart';
import 'features/tone_lab/presentation/pages/tone_lab_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KoreanToneLabApp());
}

class KoreanToneLabApp extends StatelessWidget {
  const KoreanToneLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final modelManager = ModelManager();
    final localService = LocalToneRewriteService(modelManager: modelManager);
    final mockService = MockToneRewriteService();

    return BlocProvider(
      create: (context) => ToneLabCubit(
        localService: localService,
        mockService: mockService,
        modelManager: modelManager,
      ),
      child: MaterialApp(
        title: 'Korean Tone Lab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const ToneLabPage(),
      ),
    );
  }
}
