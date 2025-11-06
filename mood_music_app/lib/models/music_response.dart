class MusicResponse {
  final String audioUrl;
  final String prompt;
  final String lyrics;
  final String sessionId;
  final String? llmTraceId;
  final String? musicTraceId;

  MusicResponse({
    required this.audioUrl,
    required this.prompt,
    required this.lyrics,
    required this.sessionId,
    this.llmTraceId,
    this.musicTraceId,
  });

  factory MusicResponse.fromJson(Map<String, dynamic> json) {
    return MusicResponse(
      audioUrl: json['audio_url'] as String,
      prompt: json['prompt'] as String,
      lyrics: json['lyrics'] as String,
      sessionId: json['session_id'] as String,
      llmTraceId: json['llm_trace_id'] as String?,
      musicTraceId: json['music_trace_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_url': audioUrl,
      'prompt': prompt,
      'lyrics': lyrics,
      'session_id': sessionId,
      'llm_trace_id': llmTraceId,
      'music_trace_id': musicTraceId,
    };
  }
}
