# Election Assistant (Flutter)

Indian election Q&A chatbot — ask about parties, flags, symbols, leaders, CMs, and the Prime Minister.

## Features

- **Chat**: Type or use voice to ask questions; bot replies with text and optional images (flags/symbols).
- **Voice input**: Speech-to-text (en-IN) via device microphone.
- **Text-to-speech**: Bot replies spoken in English (en-IN) and Tamil (ta-IN) where applicable.
- **Offline**: If the backend is unreachable, the app uses on-device NLP and data to answer.

## Prerequisites

- Flutter SDK (3.2+): [flutter.dev](https://flutter.dev)
- For voice: microphone permission on device/emulator
- Optional: Node backend from the parent project (`election-assistant/server.js`) for API responses

## Setup

1. **Generate platform projects** (if you don’t have `android/` and `ios/` yet):
   ```bash
   cd election_assistant_flutter
   flutter create . --project-name election_assistant
   ```
   Then add microphone permission:
   - **Android**: In `android/app/src/main/AndroidManifest.xml`, add `<uses-permission android:name="android.permission.RECORD_AUDIO" />` inside `<manifest>`.
   - **iOS**: In `ios/Runner/Info.plist`, add a `NSMicrophoneUsageDescription` key with a short explanation (e.g. “Voice input for election questions”).

2. Install dependencies:
   ```bash
   cd election_assistant_flutter
   flutter pub get
   ```

3. **Assets (flags/symbols)**: Copy images from the web app’s `public/assets/flags` and `public/assets/symbols` into `assets/flags/` and `assets/symbols/`. Expected names (e.g. `dmk.png`, `aiadmk.png`, `rising_sun.png`, `two_leaves.png`) — see `lib/data/parties.dart` for the full list.

4. **Backend (optional)**:
   - Run the Node server from the repo root: `node server.js` (port 5000).
   - **Android emulator**: The app uses `http://10.0.2.2:5000` by default (localhost on host).
   - **iOS simulator**: Change `baseUrl` in `lib/services/chat_service.dart` to `http://localhost:5000`.
   - **Real device**: Use your computer’s LAN IP (e.g. `http://192.168.1.x:5000`) and set it in `ChatService(baseUrl: ...)`.

## Run

```bash
flutter run
```

Build release:

```bash
flutter build apk
# or
flutter build appbundle
```

## Project structure

- `lib/main.dart` — entry point
- `lib/app.dart` — Material app and theme
- `lib/screens/chat_screen.dart` — main chat UI, voice, TTS
- `lib/services/chat_service.dart` — HTTP client + offline fallback
- `lib/utils/nlp.dart` — intent detection and local answers (mirrors Node logic)
- `lib/data/` — parties, CMs, leaders (Dart)

The backend API is **POST** `/api/chat` with body `{ "query": "..." }`, response `{ "text": "...", "image"?: "..." }`. If the request fails, the app uses `getResponse()` from `nlp.dart` locally.
