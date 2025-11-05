enum GenerationStep {
  idle,
  analyzingMood,
  generatingLyrics,
  creatingMusic,
  processingAudio,
  completed,
  error,
}

class GenerationState {
  final GenerationStep step;
  final String message;
  final double progress;
  final String? errorMessage;

  GenerationState({
    required this.step,
    required this.message,
    required this.progress,
    this.errorMessage,
  });

  bool get isLoading =>
      step != GenerationStep.idle &&
      step != GenerationStep.completed &&
      step != GenerationStep.error;

  bool get isCompleted => step == GenerationStep.completed;
  bool get hasError => step == GenerationStep.error;

  factory GenerationState.idle() {
    return GenerationState(
      step: GenerationStep.idle,
      message: '准备开始创作',
      progress: 0.0,
    );
  }

  factory GenerationState.analyzingMood() {
    return GenerationState(
      step: GenerationStep.analyzingMood,
      message: '正在分析你的心情...',
      progress: 0.25,
    );
  }

  factory GenerationState.generatingLyrics() {
    return GenerationState(
      step: GenerationStep.generatingLyrics,
      message: '正在创作歌词...',
      progress: 0.5,
    );
  }

  factory GenerationState.creatingMusic() {
    return GenerationState(
      step: GenerationStep.creatingMusic,
      message: '正在生成音乐...',
      progress: 0.75,
    );
  }

  factory GenerationState.processingAudio() {
    return GenerationState(
      step: GenerationStep.processingAudio,
      message: '正在处理音频文件...',
      progress: 0.9,
    );
  }

  factory GenerationState.completed() {
    return GenerationState(
      step: GenerationStep.completed,
      message: '创作完成！',
      progress: 1.0,
    );
  }

  factory GenerationState.error(String errorMessage) {
    return GenerationState(
      step: GenerationStep.error,
      message: '生成失败',
      progress: 0.0,
      errorMessage: errorMessage,
    );
  }
}
