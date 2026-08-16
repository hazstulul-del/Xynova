# Xynova v2 — Flutter Release

**Xynova**  
Your intelligent AI.  
Created by X Shine · 2026

This package is a real Flutter application shell designed for a secure Base44-backed AI service. It does **not** contain provider API keys and does not fabricate AI responses.

## What is included

- Premium monochrome ChatGPT-style UI
- Responsive Android/iOS/web layout
- Compact sidebar + mobile drawer
- Model selector with Auto/Fast/General/Coding/Reasoning/Vision
- Local conversation history with SharedPreferences
- Real HTTP streaming client with SSE/NDJSON support
- Stop/cancel generation
- Real camera capture through `image_picker`
- Real image/file picker
- Local text/code file extraction
- Browser/native speech recognition where supported
- Browser/native Text-to-Speech
- Markdown rendering + code blocks
- Copy/edit/delete/regenerate/read-aloud actions
- Attachment previews
- Request-id duplicate protection
- Capability-aware routing contract
- Base44 backend function reference implementation
- No authentication UI
- No hardcoded API keys
- No fake AI responses

## Important backend setup

The Flutter app calls one backend gateway:

`BASE44_FUNCTION_URL`

Set it with:

```bash
flutter run --dart-define=BASE44_FUNCTION_URL=https://YOUR-BASE44-FUNCTION-ENDPOINT
```

For release:

```bash
flutter build apk --release \
  --dart-define=BASE44_FUNCTION_URL=https://YOUR-BASE44-FUNCTION-ENDPOINT
```

The backend is responsible for:

1. xKiro
2. Groq
3. OpenRouter
4. SmartRouter
5. streaming normalization
6. secure provider keys
7. fallback
8. file processing
9. optional image generation
10. optional external TTS

### Required Base44 secrets

- `XKIRO_API_KEY`
- `GROQ_API_KEY`
- `OPENROUTER_API_KEY`

Optional:

- `IMAGE_PROVIDER_API_KEY`
- `TTS_PROVIDER_API_KEY`

Do not put these secrets in Flutter.

## Expected streaming protocol

Preferred response:

```text
data: {"type":"token","text":"Hello"}
data: {"type":"token","text":" world"}
data: {"type":"done"}
```

NDJSON is also accepted:

```text
{"type":"token","text":"Hello"}
{"type":"done"}
```

Errors:

```text
data: {"type":"error","message":"Provider sedang sibuk. Silakan coba lagi."}
```

## Android permissions

`android/app/src/main/AndroidManifest.xml` already declares:

- INTERNET
- CAMERA
- RECORD_AUDIO

For iOS, add camera/microphone/speech usage descriptions to `Info.plist`.

## Build verification

This environment may not contain the Flutter SDK, so this archive is source-complete but cannot honestly claim a local `flutter build apk` was executed here.

On a machine with Flutter stable installed:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=BASE44_FUNCTION_URL=...
```

Do not ship with an empty backend URL if real AI is required.
