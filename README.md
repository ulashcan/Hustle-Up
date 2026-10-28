# Hustle Up ⚡️

> **Make better moves.** A modern, native iOS copilot designed to help professionals and indie founders navigate high-stakes negotiations, difficult messages, and career conversations with tactical clarity.

Hustle Up breaks down complex workplace and business interactions into concrete, high-leverage action plans ("SAY THIS", "HOLD THIS", "DO THIS"). Whether analyzing conversation screenshots via on-device OCR or auditing outgoing drafts for tone risks through Fumble Check, the app provides the strategic edge needed before hitting send.

---

## ✨ Key Features

- **Strategic Move Engine:** Instantly translates challenging messages, emails, or offers into clear tactical responses with tailored leverage notes and next steps.
- **On-Device Vision OCR:** Rapidly extracts conversation context directly from screenshots using Apple's Vision framework, with built-in text cleaning and review.
- **Fumble Check:** Strategic pre-send audit that detects defensiveness, premature concessions, or leverage leaks before you hit send.
- **Interactive Practice & Scorecard:** In-app role-play scenarios that let you rehearse difficult conversations and receive actionable feedback on your communication instincts.
- **Privacy-First by Design:** No screenshot persistence, strictly local disk storage for analysis history, and zero user-content tracking in analytics.
- **Modern Swift 6 Architecture:** Built with unidirectional state flow (`AppModel`), protocol-oriented dependency injection, and complete Swift 6 strict concurrency compliance.

---

## 🛠️ Tech Stack

| Layer | Technologies |
| :--- | :--- |
| **Language** | Swift 6.0 (Complete Strict Concurrency) |
| **Framework** | SwiftUI (iOS 18.0+) |
| **Architecture** | Protocol-Oriented Architecture + State Machine (`AppModel`) |
| **Computer Vision** | Apple Vision Framework (`VNRecognizeTextRequest`) |
| **Testing** | Swift Testing framework (`@Test`, `@Suite`) & XCTest |
| **Project Spec** | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) & Xcode 16 |

---

## 🚀 Getting Started

### Prerequisites

- macOS 14.5+ (Sonoma or Sequoia)
- Xcode 16.0 or later
- iOS 18.0+ Simulator or physical device

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ulashcan/Hustle-Up.git
   cd Hustle-Up
   ```

2. **Open the project in Xcode:**
   ```bash
   open HustleUp.xcodeproj
   ```
   *(Optional: If you use [XcodeGen](https://github.com/yonaskolb/XcodeGen), you can regenerate the Xcode project at any time with `xcodegen generate`.)*

3. **Configure Environment (Optional):**
   The app runs fully out-of-the-box with deterministic mock engines and local heuristics. To connect a custom AI backend:
   ```bash
   cp .env.example .env
   # Add your key to .env:
   # HUSTLEUP_AI_KEY=your_secret_key_here
   ```

4. **Run Tests:**
   Press `Cmd + U` in Xcode or run via terminal:
   ```bash
   xcodebuild test -project HustleUp.xcodeproj -scheme HustleUp -destination 'platform=iOS Simulator,name=iPhone 16'
   ```

---

## 🏛️ Project Structure

```
HustleUp/
├── App/                  # App environment, routing, and unidirectional AppModel
├── Data/                 # Protocol-backed services (AI, Vision OCR, Storage, Analytics)
├── DesignSystem/         # HUTheme styling tokens, custom buttons, cards, and banners
├── Domain/               # Pure domain logic (Parsing, Intent Detection, Fumble Engine)
├── Features/             # Independent SwiftUI feature views (Analysis, Practice, FumbleCheck)
└── Assets.xcassets/      # Adaptive color palettes and visual assets
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — see the LICENSE file for details.

