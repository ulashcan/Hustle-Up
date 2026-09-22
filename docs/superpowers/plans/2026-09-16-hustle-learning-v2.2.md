# Hustle Learning V2.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development. No git commit unless the user asks. Do not fake StoreKit or hosted AI.

**Goal:** Close the loop: MOVE → DID IT WORK? → lesson in history → profile notes that are counts, not personality.

**Architecture:** Add `MoveOutcome` onto `StoredAnalysis`. `FileAnalysisStore.update` persists it. `OutcomeLesson` is a template from move+result. `HustleProfileBuilder` emits observations only when the same move+result appears at least twice. No screenshot bytes. No user text in analytics or profile copy.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, existing `FileAnalysisStore`.

## Global Constraints

- Outcomes: YES / NO / PARTLY / NOT SURE.
- Store only outcome enum + lesson template + timestamp. Not a diary of the other person.
- Profile never invents “over-explains” / “anxious” / diagnoses. Counts only.
- Practice scorecards are not profile evidence.
- DID IT WORK is free (retention). History list + profile stay Pro.
- No StoreKit, no hosted AI, no voice.

## Files

| New | Job |
| --- | --- |
| `Domain/Models/MoveOutcome.swift` | Enum + record + lesson copy |
| `Domain/Parsing/HustleProfileBuilder.swift` | Observations from ≥2 matching outcomes |
| `Features/Profile/ProfileView.swift` | Why a pattern was inferred |
| `Features/Shared/OutcomePrompt.swift` | 2×2 DID IT WORK control |
| `HustleUpTests/LearningTests.swift` | Persistence, profile honesty, AppModel |

| Change | Job |
| --- | --- |
| `StoredAnalysis` | Optional `outcome` |
| `FileAnalysisStore` | `update` |
| `AppModel` | `recordOutcome`, `openProfile` |
| Home / Analysis / History rows / Paywall / analytics / docs |

## Tasks

- [ ] Tests for decode defaults, persist, threshold-2 profile, no user text in profile
- [ ] Models + store + builder + AppModel
- [ ] UI + analytics + docs
- [ ] Unit + isolated UI tests
