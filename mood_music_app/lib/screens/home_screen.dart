import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/generation_state.dart';
import '../models/music_response.dart';
import '../services/minimax_service.dart';
import '../widgets/mood_input_section.dart';
import '../widgets/progress_section.dart';
import '../widgets/result_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  GenerationState _state = GenerationState.idle();
  MusicResponse? _musicResponse;

  final List<String> _quickMoods = [
    '开心',
    '难过',
    '平静',
    '兴奋',
    '焦虑',
    '放松',
    '怀念',
    '孤独',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  Future<void> _loadSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApiKey = prefs.getString('api_key');
    if (savedApiKey != null && savedApiKey.isNotEmpty) {
      setState(() {
        _apiKeyController.text = savedApiKey;
      });
    }
  }

  Future<void> _saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
  }

  @override
  void dispose() {
    _moodController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _selectQuickMood(String mood) {
    setState(() {
      _moodController.text = mood;
    });
  }

  Future<void> _generateMusic() async {
    final mood = _moodController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (mood.isEmpty) {
      _showError('请输入你的心情');
      return;
    }

    if (apiKey.isEmpty) {
      _showError('请输入 MiniMax API Key');
      return;
    }

    // Save API Key for future use
    await _saveApiKey(apiKey);

    setState(() {
      _state = GenerationState.analyzingMood();
      _musicResponse = null;
    });

    try {
      final service = MinimaxService(apiKey: apiKey);
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      final response = await service.generateFromMood(
        mood,
        sessionId,
        onProgress: (message) {
          if (!mounted) return;

          setState(() {
            if (message.contains('分析')) {
              _state = GenerationState.analyzingMood();
            } else if (message.contains('歌词')) {
              _state = GenerationState.generatingLyrics();
            } else if (message.contains('生成音乐')) {
              _state = GenerationState.creatingMusic();
            } else if (message.contains('处理音频')) {
              _state = GenerationState.processingAudio();
            } else if (message.contains('完成')) {
              _state = GenerationState.completed();
            }
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _state = GenerationState.completed();
        _musicResponse = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _state = GenerationState.error(e.toString());
      });
      _showError('生成失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _reset() {
    setState(() {
      _state = GenerationState.idle();
      _musicResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B9D),  // Pink
              Color(0xFFFFC3E1),  // Light pink
              Color(0xFFFFE5F1),  // Pale pink
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 20),
                const Text(
                  '🎵 心情音乐生成器',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  '用 AI 将你的心情转化为独特的音乐',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Input Section
                MoodInputSection(
                  moodController: _moodController,
                  apiKeyController: _apiKeyController,
                  quickMoods: _quickMoods,
                  onQuickMoodSelected: _selectQuickMood,
                  onGenerate: _generateMusic,
                  isLoading: _state.isLoading,
                ),

                const SizedBox(height: 30),

                // Progress Section
                if (_state.isLoading || _state.isCompleted || _state.hasError)
                  ProgressSection(state: _state),

                const SizedBox(height: 30),

                // Result Section
                if (_musicResponse != null)
                  ResultSection(
                    response: _musicResponse!,
                    onReset: _reset,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
