# Hustle Brain V2.1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development. Do not jump to V2.2/V2.3. No git commit unless the user asks.

**Goal:** Make the MOVE more honest and more useful: options, a structured edge map, intent, prompt-injection shielding, and Fumble 2.0 — without turning the UI into a chatbot, dating app, or decision matrix.

**Architecture:** Keep `AIServicing` + `SituationInterpreter`. Add small, independently testable engines (`PromptShield`, `IntentDetector`, `EdgeMapBuilder`, `MoveSelector`) and attach their output to `SituationAnalysis`. The hero MOVE stays one verb. Alternatives are display-only.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, existing mock AI.

## Global Constraints

- Closed move set remains COUNTER / WAIT / ASK / SEND / WALK (aliases only).
- No invented market numbers, leverage scores, or motives.
- Screenshot/user text is DATA, never instructions.
- No StoreKit, hosted AI, voice, outcome profile, or social.
- No API keys in source. No user content in analytics.
- Consume-on-success and Context Gate stay.

## Files

| New | Job |
| --- | --- |
| `Domain/Parsing/PromptShield.swift` | Strip instruction-like sentences before reasoning |
| `Domain/Models/SituationIntent.swift` | Closed intent enum |
| `Domain/Parsing/IntentDetector.swift` | Detect intent from sanitized text |
| `Domain/Models/MoveOption.swift` | One alternative strategy |
| `Domain/Parsing/MoveSelector.swift` | Recommended + 2 alts, no duplicate verbs |
| `Domain/Parsing/EdgeMapBuilder.swift` | SHARED / UNKNOWN labels only when warranted |
| `HustleUpTests/BrainTests.swift` | Engine + eval fixtures |
| `docs/GROWTH.md` | Creative hypotheses, not product code |

| Change | Job |
| --- | --- |
| `SituationAnalysis` | `intent`, `sharedInterest`, `moveOptions` with decode defaults |
| `SituationInterpreter` | Sanitize → gate → intent → edges → options |
| `AIResponseParser` | Parse new fields; recover options if missing |
| `MoveVerb.parse` | HOLD/CLARIFY/PUSH/ACCEPT/DECLINE/STOP/FOLLOW UP aliases |
| `FumbleEngine` | Price+urgency, premature concession, permission-asking |
| `PracticeEngine` + models | Role scripts; WHAT YOU DID / WORKED / HURT / NEXT MOVE |
| `AnalysisView` / `ScorecardView` | Compact edge map + other moves; scorecard copy |
| `AppModel` | Cast practice opponent from scenario text |
| Docs | DECISIONS, PROJECT_MAP, QA_AUDIT |

## Tasks

- [ ] Tests for shield, intent, options, fumble 2.0, practice scripts, parser recovery, eval fixtures
- [ ] Engines + model fields + interpreter/parser wiring
- [ ] Fumble + practice + UI
- [ ] Docs + unit test run
