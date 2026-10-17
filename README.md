# EzboAI Mobile — Production Cross-Platform Flutter Application (iOS & Android)

A full-featured, cross-platform mobile application for [EzboAI](https://ezboai.com), replicating 100% of the live web app's capabilities, aesthetics, and branding.

---

## 🎨 Branding & Design System
- **Theme:** Ultra-sleek dark mode
- **Backgrounds:** `#09090B` deep dark canvas with `#18181B` card surfaces
- **Accents:** Electric Indigo (`#6366F1`), Violet (`#8B5CF6`), and Purple (`#A855F7`)
- **Typography:** Inter (via Google Fonts) with crisp hierarchy and micro-interactions

---

## 🚀 Key Features

### 1. Authentication & Session Persistence
- Secure login and registration with validation
- OTP email verification bridge
- Secure JWT storage with auto-login on app launch (`flutter_secure_storage`)
- Password reset flow

### 2. AI Chat & Real-Time Token Streaming
- Real-time Server-Sent Events (SSE) streaming reader (`/api/chat-stream`)
- Model Selector Sheet with capability badges (Ezbo Flash, Claude 3.5, GPT-4o, DeepSeek R1)
- Web Search toggle mode (`:online`)
- Multimodal file & image picker (Camera, Gallery, PDF, TXT)
- Markdown rendering with code blocks and one-tap **Copy Code**
- **Read Aloud** TTS audio playback for AI messages
- Chat Drawer with search, pinning, renaming, and deleting conversations

### 3. All-in-One Studio
- **Image Generation:** Text-to-image with prompts, styles, quality, and aspect ratio chips (`1:1`, `16:9`, `9:16`, `4:3`)
- **Video Generation:** Text-to-video / Image-to-video generation
- **Music Generation:** AI instrumental & vocal music generator with waveform player
- **Sound Effects (SFX):** Realistic sound fx generator with duration slider (1s - 20s)
- **Text-to-Speech (TTS):** Lifelike voice synthesis with character picker

### 4. Projects Workspace
- Multi-project management
- Custom System Instructions per project (AI strictly adheres to project guidelines)
- Context file tracking and scoped chat launching

### 5. Central Library
- Unified media repository for all user creations (Images, Videos, Music, SFX, Audio)
- Interactive zoomable full-screen viewer (`InteractiveViewer`)
- Native share and download capabilities

### 6. Credits, Usage & Subscriptions
- Real-time credit balance display and usage breakdown
- Pricing plans carousel (Free, Starter, Pro, Advanced)
- Manual payment gateway checkout (Binance, Bybit, Wise, PayPal, OpayBD)

---

## 📱 How to Run & Build

### Prerequisites
1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install) (version `>= 3.0.0`).
2. Run `flutter doctor` to ensure Android/iOS toolchains are set up.

### Install Dependencies
```bash
flutter pub get
```

### Run in Debug Mode
```bash
flutter run
```

### Build Android APK (Release)
```bash
flutter build apk --release
```
The generated APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### Build iOS Bundle
```bash
flutter build ipa --release
```
