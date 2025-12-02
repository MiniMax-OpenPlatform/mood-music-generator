# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a mood-based music generation application available in both Web and Android versions. Users input their current mood and MiniMax API key, and the system generates custom music with lyrics that can be shared on social media.

**Tech Stack:**

*Web Version:*
- Backend: Python + FastAPI
- Frontend: HTML5 + CSS3 + Vanilla JavaScript

*Android Version:*
- Framework: Flutter 3.19.0 + Dart
- UI: Material Design 3 with pink gradient theme
- HTTP Client: Dio
- Audio: audioplayers
- State Management: Provider
- Sharing: share_plus

*AI Services:*
- MiniMax LLM (MiniMax-Text-01) - Mood analysis and lyrics generation
- MiniMax Music API (music-2.0) - Music generation

## Common Commands

### Web Development

**传统方式（Python 直接运行）：**
```bash
# Install Python dependencies
pip install -r requirements.txt

# Start development server (with auto-reload)
uvicorn main:app --host 0.0.0.0 --port 5111 --reload

# Start production server
python3 main.py

# Or use the startup script
./start.sh

# Stop server
pkill -f "python3 main.py"

# Run in background
nohup python3 main.py > app.log 2>&1 &
```

**Docker 方式（推荐生产环境）：**
```bash
# Quick start with Docker Compose
docker compose up -d

# View logs
docker compose logs -f

# Stop service
docker compose down

# Build image manually (if needed)
docker build -t mood-music-generator:latest .

# Run with Docker
docker run -d --name mood-music-generator -p 5111:5111 mood-music-generator:latest
```

**详细文档**: 参考 [DOCKER.md](DOCKER.md)

**访问地址：**
```
主页: http://localhost:5111/moodmusic/
健康检查: http://localhost:5111/moodmusic/health
API 端点:
  - /moodmusic/generate_prompt (生成提示词和歌词)
  - /moodmusic/generate_music (生成音乐)
  - /moodmusic/generate (完整流程，兼容旧版)
```

**注意:** 所有 Web 服务路由都使用 `/moodmusic` 前缀，前端使用相对路径进行 API 调用。

### Android Development

```bash
# Navigate to Flutter app directory
cd mood_music_app

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build APK (all architectures)
flutter build apk --release --split-per-abi

# Build outputs are in:
# mood_music_app/build/app/outputs/flutter-apk/
# - app-arm64-v8a-release.apk (recommended for most devices)
# - app-armeabi-v7a-release.apk (older devices)
# - app-x86_64-release.apk (emulators)
```

### Configuration

**Important:** API Key is provided by users at runtime via the UI - no `.env` file needed for basic operation. The `.env.example` file exists but the default port is 5111.

## Architecture

### Web App Request Flow

1. **User Input** → User enters API key + mood description in frontend
2. **Mood Analysis** → Backend calls MiniMax LLM API (`generate_music_prompt_with_llm`)
   - Analyzes mood
   - Generates music style prompt (Chinese description)
   - Creates structured lyrics with [Intro], [Verse], [Chorus], [Bridge], [Outro] tags
3. **Music Generation** → Backend calls MiniMax Music API (`generate_music`)
   - Uses prompt and lyrics from step 2
   - Returns audio data in hex format
4. **Audio Processing** → Convert hex to binary and save as MP3
5. **Response** → Return audio URL, prompt, and lyrics to frontend
6. **Playback** → Frontend displays lyrics and plays audio with HTML5 audio player

### Android App Request Flow

1. **User Input** → User enters API key + mood in Flutter UI
2. **Service Call** → `MinimaxService.generateFromMood()` orchestrates the process
3. **LLM Request** → `generatePromptAndLyrics()` calls MiniMax LLM API
   - Returns prompt and lyrics in JSON format
   - Extracts trace_id for debugging
4. **Music Request** → `generateMusic()` calls MiniMax Music API with `output_format: 'url'`
   - API returns direct URL to audio file (not hex data)
   - Extracts trace_id from response body
5. **Result Display** → `MusicResponse` object contains audioUrl, prompt, lyrics, and trace IDs
6. **Playback** → `audioplayers` package streams audio from URL

### Key Components

**Web Backend (`main.py`):**
- `generate_music_prompt_with_llm()` - LLM integration for mood analysis
- `generate_music()` - Music generation API integration
- `/generate` endpoint - Main API (receives api_key + mood as form data)
- `/download/{session_id}/{filename}` - Audio file serving
- `/health` endpoint - Health check

**Web Frontend:**
- `templates/index.html` - Main UI with mood input form and API key field
- `static/js/app.js` - Handles form submission, audio playback, sharing
- `static/css/style.css` - Pink gradient design with animations

**Android App Structure:**
- `lib/main.dart` - App entry point, MaterialApp with pink theme
- `lib/screens/home_screen.dart` - Main screen with state management
- `lib/services/minimax_service.dart` - MiniMax API client
  - Handles both LLM and Music API calls
  - Extracts trace_id for debugging
  - Uses `output_format: 'url'` to get direct audio URLs
- `lib/models/` - Data models (MusicResponse, GenerationState)
- `lib/widgets/` - Reusable UI components (MoodInputSection, ProgressSection, ResultSection)

### API Integration Details

**MiniMax LLM API:**
- Endpoint: `https://api.minimaxi.com/v1/text/chatcompletion_v2`
- Model: `MiniMax-Text-01`
- Auth: Bearer token in `Authorization` header
- Request includes system prompt defining JSON output format
- Response contains trace_id in headers (Web) or body (may vary)
- Output: JSON with `prompt` (music style) and `lyrics` (song structure)

**MiniMax Music API:**
- Endpoint: `https://api.minimaxi.com/v1/music_generation`
- Model: `music-2.0`
- Auth: Bearer token in `Authorization` header
- Parameters:
  - `prompt`: Music style description
  - `lyrics`: Song lyrics with structure tags
  - `audio_setting`: {sample_rate: 44100, bitrate: 256000, format: 'mp3'}
  - `output_format`: 'url' (Android) or omit for hex (Web)
- Web response: Audio as hex string in `data.audio` field
- Android response: Direct URL in `data.audio` field
- Response includes trace_id in body `trace_id` field

**Important Differences:**
- Web backend converts hex to MP3 file and serves it
- Android uses `output_format: 'url'` to get direct streaming URL
- Both platforms extract trace_id for debugging purposes

### File Storage

**Web App:**
- Generated audio files stored in `temp_sessions/{session_id}/`
- Format: `music_{timestamp}.mp3`
- Files persist until manually cleaned
- Clean up with: `find temp_sessions/ -type f -mtime +7 -delete`

**Android App:**
- No local file storage required (streams from URL)
- API key stored in shared_preferences for convenience

## Development Notes

### Testing API Integration

Before running the app, ensure:
1. Valid MiniMax API key (get from https://platform.minimaxi.com/user-center/basic-information/interface-key)
2. Sufficient API credits in account
3. Network access to `api.minimaxi.com`
4. For Android: Physical device or emulator with internet access

### Error Handling

**Web App:**
- Invalid/missing API key → 400 error
- LLM API failures → Falls back to default prompt/lyrics
- Music API failures → Returns HTTP error to frontend
- Missing audio files → 404 response

**Android App:**
- Network errors → User-friendly error messages
- LLM failures → Fallback to default Chinese lyrics
- Music API failures → Shows trace_id for debugging
- Timeout settings: 30s connect, 120s receive

### Debugging

**Trace IDs:**
Both platforms capture trace_id from API responses for debugging:
- Web: Logged to console
- Android: Displayed in UI and logged to console
- Use trace_id when contacting MiniMax support

### CI/CD Automation

**GitHub Actions Workflows:**

`.github/workflows/build-apk.yml`:
- Triggers on push to `master` when `mood_music_app/**` changes
- Manual trigger via "Run workflow" button
- Builds split APKs for arm64-v8a, armeabi-v7a, x86_64
- Automatically creates GitHub Release with APK files
- Release naming: `v{date}-{short-sha}`

`.github/workflows/build-ios.yml`:
- iOS build workflow (unsigned)
- Requires manual signing before distribution

**Release Process:**
1. Push changes to `master` branch
2. If `mood_music_app/` modified, APK build auto-triggers
3. Or manually trigger from Actions tab
4. Check build status at: https://github.com/[owner]/[repo]/actions
5. Download APKs from Releases page

### Known Limitations

- Web: No rate limiting implemented
- Web: No user authentication
- Web: Temporary files not auto-cleaned
- Web: LLM response parsing may fail if JSON format is incorrect (has fallback)
- Android: No offline mode (requires internet for API calls)

## Customization

### Modify Music Generation Parameters

**Web:** Edit `main.py:107`, function `generate_music()`:
```python
"audio_setting": {
    "sample_rate": 44100,  # Sample rate
    "bitrate": 256000,     # Bitrate
    "format": "mp3"        # Format (mp3/wav)
}
```

**Android:** Edit `mood_music_app/lib/services/minimax_service.dart:135`:
```dart
'audio_setting': {
  'sample_rate': 44100,
  'bitrate': 256000,
  'format': 'mp3',
}
```

### Modify LLM Prompts

**Web:** Edit `main.py:22`, function `generate_music_prompt_with_llm()`, in the `messages` array at line 33-68.

**Android:** Edit `mood_music_app/lib/services/minimax_service.dart:28`, in the `messages` array at line 40-55.

### Modify UI Themes

**Web:** Edit `static/css/style.css`, change gradient colors in:
- `body` background
- `.btn-primary` background

**Android:** Edit `mood_music_app/lib/main.dart:34`:
```dart
seedColor: const Color(0xFFFF6B9D),  // Pink theme color
```

### Change Default Port

Edit `.env` file (create from `.env.example`):
```
PORT=8080  # Change to desired port
```

Or pass directly when running:
```bash
PORT=8080 python3 main.py
```
