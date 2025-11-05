class MusicResponse {
  final String audioUrl;
  final String prompt;
  final String lyrics;
  final String sessionId;

  MusicResponse({
    required this.audioUrl,
    required this.prompt,
    required this.lyrics,
    required this.sessionId,
  });

  factory MusicResponse.fromJson(Map<String, dynamic> json) {
    return MusicResponse(
      audioUrl: json['audio_url'] as String,
      prompt: json['prompt'] as String,
      lyrics: json['lyrics'] as String,
      sessionId: json['session_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audio_url': audioUrl,
      'prompt': prompt,
      'lyrics': lyrics,
      'session_id': sessionId,
    };
  }
}
