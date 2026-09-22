# HUSTLE UP MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a production-shaped iOS MVP where a user can capture a situation, get a structured move, run Fumble Check and Practice, and hit honest error/paywall states.

**Architecture:** SwiftUI app with `AppModel` + protocol services. UI never parses LLM prose. OCR via Vision. AI mock by default.

**Tech Stack:** iOS 18, Swift 6, SwiftUI, Observation, PhotosUI, Vision, Swift Testing, XCTest UI tests, xcodegen.

## Global Constraints

- Bundle ID `com.hustleup.app`; display name `HUSTLE UP`
- No API keys in source; no screenshot persistence; no analytics content payloads
- Move verbs only: COUNTER, WAIT, ASK, SEND, WALK
- Do not invent market numbers
- No TODO left on shipped features
- User did not request git commits — skip commit steps

---

### Task 1: Domain models + AI parser

**Files:**
- Create: `HustleUp/Domain/Models/*.swift`
- Create: `HustleUp/Domain/Parsing/AIResponseParser.swift`
- Test: `HustleUpTests/AIResponseParserTests.swift`

**Interfaces:**
- Produces: `SituationAnalysis`, `MoveVerb.parse`, `AIResponseParser.parseAnalysis(_:)`

- [x] Models and parser with unit tests for success, missing fields, unknown move, wrapped JSON, empty situation

### Task 2: OCR helpers

**Files:**
- Create: `HustleUp/Data/OCR/TextCleaner.swift`
- Create: `HustleUp/Data/OCR/ImageValidator.swift`
- Create: `HustleUp/Data/OCR/VisionOCRService.swift`
- Test: `HustleUpTests/TextCleanerTests.swift`, `ImageValidatorTests.swift`

- [x] Cleaner truncates, strips junk; validator rejects empty/tiny; OCR service does not crash on failure

### Task 3: Entitlements, analytics, store

**Files:**
- Create: `HustleUp/Data/Entitlements/EntitlementStore.swift`
- Create: `HustleUp/Data/Analytics/AnalyticsTracking.swift`
- Create: `HustleUp/Data/Persistence/FileAnalysisStore.swift`
- Test: matching test files

- [x] Free limit 3; Pro gates fumble/practice/history; analytics API cannot take message text; store never writes images

### Task 4: AI services + AppModel

**Files:**
- Create: `HustleUp/Data/AI/*.swift`
- Create: `HustleUp/App/*.swift`
- Test: `HustleUpTests/MockAIServiceTests.swift`, `AppModelTests.swift`

- [x] Mock routes by situation language; failures map to AppError; AppModel wires analyze/ocr/paywall

### Task 5: Design system + screens

**Files:**
- Create: `HustleUp/DesignSystem/*.swift`
- Create: `HustleUp/Features/**/*.swift`
- Create: `HustleUp/HustleUpApp.swift`

- [x] Home, compose, OCR review, analysis hero, fumble, practice, paywall, settings, onboarding

### Task 6: Project, tests, QA

**Files:**
- Create: `project.yml`, assets, Info, privacy manifest, UI tests

- [x] `xcodegen` + `xcodebuild test`
- [ ] Fix until clean
- [ ] Simulator smoke of core flow
