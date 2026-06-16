

https://github.com/user-attachments/assets/50b537df-5fcc-4ef2-9fc6-734b877a2fa7



# Sign Speak AI

Sign Speak AI is a Flutter Android app for real-time sign recognition, hand
tracking, learning, practice, quiz, emergency phrases, and text-to-speech.

The project focuses on a polished mobile experience: a live camera screen,
smooth hand skeleton overlay, confidence scoring, visual learning cards, and
offline local app logic.

## Features

- Real-time camera preview
- 21-point hand landmark skeleton overlay
- Live sign prediction with confidence score
- Translation sentence builder
- Text-to-speech
- Learning mode with visual sign guides
- Practice mode
- Quiz mode with unlabeled sign images
- Emergency phrase cards
- Translation history
- Dark animated UI
- Offline-first local logic

## Tech Stack

- Flutter
- Dart
- Riverpod
- Camera
- Hand landmark detection
- CustomPainter overlays
- Flutter TTS
- SharedPreferences

## Supported Experience

The app includes a focused set of camera-readable signs and matching visual
lessons. Quiz images are stored separately so the question image does not reveal
the answer.

## Project Structure

```text
lib/                     Flutter source code
android/                 Android project files
assets/sign_images/      Labeled learning and practice images
assets/sign_quiz_images/ Unlabeled quiz images
test/                    Flutter tests
```

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
dart format lib test
flutter analyze
flutter test
```

## Android Release Build

```bash
flutter build appbundle --release
```
