# 📋 AI Tutor Phase 1 Development Task & Progress Tracking

This document outlines the Phase 1 goals, inspection findings, completed deliverables, verification test results, and Phase 2 roadmap.

---

## 📌 Status Summary

- **Current Phase**: Phase 1 Foundation — **COMPLETE**
- **Test Status**: 9/9 Unit and Widget tests passing.
- **Git Branch**: `phase-1-foundation`
- **Remote**: `https://github.com/SalmanKhan-cyber/ai-turor`

---

## ✅ Completed Phase 1 Checklist

### 1. Project Inspection & Working Baseline
- [x] Inspected workspace and GitHub remote repository.
- [x] Resolved Flutter environment lockfile blockages on Windows.
- [x] Initialized clean Git tracking with `main` and feature branch `phase-1-foundation`.
- [x] Validated Dart SDK (v3.13.7) and Flutter SDK (v3.47.9).
- [x] `flutter pub get` verified.
- [x] `flutter analyze` verified (0 fatal errors).
- [x] `flutter test` verified (9 passed tests).

### 2. UI / UX Design (Light Theme Only)
- [x] Enforced strict Light Theme: clean white cards, soft blue scaffolding, `#2196F3` primary blue, `#4DD0A4` mint accents.
- [x] Material 3 design with responsive layouts across mobile and wide viewports.
- [x] Rounded button shapes, elevation control, and accessible typography.

### 3. Core Screens & Features
- [x] **Home Screen**: AI Tutor branding, Hero card, Quick Ask search bar, 6 Subject categories, Education level card, and navigation stack.
- [x] **AI Tutor Chat Screen**:
  - Student message bubbles (blue, right-aligned / RTL-aware).
  - AI Tutor bubbles (light-tinted, left-aligned, Markdown rendering for formulas/code/lists).
  - Voice output (TTS) with play/stop toggle on every AI response.
  - Speech-to-Text (STT) input with animated microphone toggle.
  - Suggestion prompt chips for quick subject exploration.
  - Clear conversation dialog with confirmation protection.
- [x] **Language Selection**:
  - English, Urdu (اردو), Pashto (پښتو).
  - Dynamic Right-to-Left (RTL) layout switching for Urdu and Pashto.
  - Localized UI dictionary and translated subject descriptions.
- [x] **Education Level Adaptability**:
  - Primary School (Class 1-5).
  - Middle School (Class 6-8).
  - High School (Class 9-12).
  - College (Intermediate).
  - University (Undergraduate & Postgraduate).
  - Dynamic prompt hints injected into AI system instructions.
- [x] **Voice Features**:
  - `TtsService`: Text-to-Speech audio reader with markdown stripping and locale detection.
  - `SttService`: Speech-to-Text input with dictation support and permission failure handling.
  - Device diagnostic overview in Settings displaying real-time voice availability per language.
- [x] **Settings Screen**:
  - Visual language switcher.
  - Education level radio picker.
  - Voice engine platform diagnostic indicators.
  - Supabase URL and Anon key credentials manager with secure storage.

### 4. Backend & Security Architecture
- [x] Supabase Edge Function (`supabase/functions/gemini-chat/index.ts`):
  - Server-side `GEMINI_API_KEY` handling.
  - 32KB payload size limits & 4000 character input validation.
  - Robust CORS configuration for web and native clients.
  - Pedagogical system prompts enforcing step-by-step guidance.
  - Child safety and content moderation rules.
- [x] PostgreSQL Schema (`supabase/migrations/20261109000000_init_schema.sql`):
  - `profiles`, `conversations`, and `messages` tables.
  - Row Level Security (RLS) policies isolating each student's records.
  - Automatic profile creation trigger on signup.
  - Performance indexes on foreign keys.

---

## 🔬 Voice Engine Platform Observations

| Language | Android | iOS | Windows 11 | Web |
| :--- | :--- | :--- | :--- | :--- |
| **English** | Native (High Quality) | Native (Siri Voices) | Native (OneCore) | Web Speech API |
| **Urdu (اردو)** | Supported via Google TTS | Supported via iOS Urdu voice | Requires Windows Urdu Language Pack installed in OS Settings | Dependent on browser speech engine (Chrome supports ur-PK) |
| **Pashto (پښتو)** | Limited device TTS support | Limited device TTS support | Limited (fallback to text) | Limited (fallback to text) |

*The app incorporates an automatic fallback mechanism: if Urdu or Pashto speech synthesis or recognition is missing on the host device, it displays helpful notifications and allows full text-based interaction without crashing.*

---

## 🔮 Phase 2 Roadmap

1. **Supabase User Authentication**: Email/Password signup, Google Sign-in, and guest/anonymous sessions.
2. **Cloud Conversation Sync**: Syncing chat history and learning progress across devices via Supabase DB.
3. **Advanced Math & LaTeX Rendering**: Native KaTeX / MathJax rendering for complex algebra, calculus formulas, and chemistry equations.
4. **Interactive Quiz & Mastery Mode**: AI-generated practice questions and progress badges after each study session.
5. **Parental Dashboard & Time Limits**: Optional PIN-protected controls for young learners.
