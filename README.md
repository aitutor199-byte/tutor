# 🎓 AI Tutor — Phase 1 Foundation

**AI Tutor** is a multilingual, AI-powered personal education assistant built for students from Class 1 to university level. It provides step-by-step tutoring, conceptual clarity, and friendly guidance in **English, Urdu (اردو), and Pashto (پښتو)** across mathematics, science, English, computer science, and university-level subjects.

---

## 🌟 Key Highlights

- **Light Mode by Design**: Clean, welcoming educational aesthetic with crisp white and light blue surfaces, primary blue brand accents, and soft mint-green highlights.
- **Multilingual & RTL Support**: Native support for English, Urdu, and Pashto with automatic Right-to-Left (RTL) text rendering.
- **Socratic & Step-by-Step AI**: Guided by custom system instructions tailored to 5 education tiers (Primary, Middle, High School, College, University).
- **Secure Server-Side AI**: Powered by Google Gemini via Supabase Edge Functions. Zero API secrets stored in the client application.
- **Voice Capabilities**: Speech-to-Text (STT) voice question input and Text-to-Speech (TTS) response playback with graceful fallbacks.
- **Cross-Platform Ready**: Flutter architecture prepared for Android, iOS, Web, Windows, macOS, and Linux.

---

## 📱 App Walkthrough

### 1. Home Screen
- **Branding & Welcome**: Friendly hero card introducing students to their AI learning companion.
- **Quick Ask Bar**: Fast one-tap navigation to the chat tutor.
- **Subject Grid**:
  - 🔢 **Mathematics**: Algebra, Geometry, Calculus, Word Problems.
  - 🔬 **Science**: Physics, Chemistry, Biology, Environmental Sciences.
  - 📖 **English**: Grammar, Essay Writing, Literature, Comprehension.
  - 💻 **Computer Science**: Programming concepts, Algorithms, Logic.
  - 🎓 **University**: Advanced academic and research inquiries.
  - 💡 **Ask Anything**: General knowledge and multidisciplinary curiosity.
- **Education Level Selector**: Dynamic tier switcher adapting explanation depth.

### 2. AI Tutor Chat
- **Markdown Bubble Rendering**: Formats formulas, bold definitions, code snippets, and numbered steps.
- **Voice Output (TTS)**: Listen to AI explanations aloud with play/stop controls.
- **Voice Input (STT)**: Dictate questions using the microphone button.
- **Smart Suggestions**: Quick prompt chips to get started immediately.
- **Demo Mode**: Built-in interactive test responses before backend credentials are configured.

### 3. Settings & Configuration
- **One-Tap Language Switching**: English, Urdu, Pashto.
- **Education Level Picker**: Primary (1-5), Middle (6-8), High (9-12), College, University.
- **Voice Engine Diagnostics**: Visual detection of installed TTS/STT voices on the user's device.
- **Supabase Backend Configuration**: Direct input fields for Supabase Project URL and Anon Key.

---

## 🔒 Security & Privacy

- **Client-Side Secret Isolation**: No Google Gemini API key or Supabase Service Role key is ever compiled into the Flutter app or committed to version control.
- **Row Level Security (RLS)**: PostgreSQL tables ensure each student can only view, edit, or delete their own chat conversations and profile details.
- **Child Safety Guidelines**: Edge Function system prompt explicitly enforces safe, age-appropriate educational discourse and rejects harmful content.
- **Minimal Data Footprint**: No unnecessary personal identifiable information (such as home address, phone numbers, or real-name requirements) is requested.

---

## 🚀 Quick Start on Windows 11

### Prerequisites
- [Flutter SDK 3.24+](https://docs.flutter.dev/get-started/install/windows)
- [Git](https://git-scm.com/)
- [Google Chrome](https://www.google.com/chrome/) (for Flutter Web) or Visual Studio 2022 C++ tools (for Windows desktop)

### Running the Application

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/SalmanKhan-cyber/ai-turor.git
   cd ai-turor
   ```

2. **Get dependencies:**
   ```powershell
   flutter pub get
   ```

3. **Run tests:**
   ```powershell
   flutter test
   ```

4. **Launch the application:**
   - **On Web (Chrome):**
     ```powershell
     flutter run -d chrome
     ```
   - **On Windows Desktop:**
     ```powershell
     flutter run -d windows
     ```

*Note: For Windows desktop builds with plugins, enable Developer Mode in Windows Settings (`ms-settings:developers`). Flutter Web runs immediately without Developer Mode.*

---

## 📚 Documentation Links

- [ARCHITECTURE.md](ARCHITECTURE.md) — Architectural patterns, state flow, and data diagrams.
- [SETUP.md](SETUP.md) — Step-by-step Supabase backend and Gemini API deployment guide.
- [DEVIN_TASK.md](DEVIN_TASK.md) — Development task specification, milestones, and Phase 2 roadmap.
