# HUSTLE UP — Project Map

**MAKE BETTER MOVES.**

This map is the source of truth for the MVP. It records what exists, what we are building, what depends on what, and what must be tested before moving forward.

## Audit (2026-09-17, execute loop)

| Item | State |
| --- | --- |
| Repository | Native SwiftUI app in tree. Not a git repo. |
| Quality gate | Unit tests on iPhone 17. Isolated UI tests. StoreKit / live AI / device OCR still external. |
| V2.1 Brain | Context Gate + PromptShield + Intent + Edge Map + Move Options + Fumble 2.0. |
| V2.2 Learning | DID IT WORK outcomes, history as lessons, profile from ≥2 matching outcomes. |
| Execute loop | Fumble primary. Outcomes Home-only. Empty OCR has no error banner. WAIT is HOLD THIS. |

## Skills actually used

| Skill | Purpose |
| --- | --- |
| `superpowers:using-superpowers` | Skill discovery before work |
| `superpowers:writing-plans` | V2.1 Brain plan |
| `superpowers:test-driven-development` | Domain tests before treating Brain as done |
| `superpowers:verification-before-completion` | No “done” without a passing build/test run |
| Web research | Short-form creative patterns for `docs/GROWTH.md` |

Skills inspected and **not** applicable: Remotion, Notion, Link wallet, Cursor SDK, git worktrees (no git repo yet). No iOS HIG skill in this environment.

---

## 1. Product architecture

Single iOS app. One loop:

```
HOME → INPUT → ANALYZE → MOVE → act → DID IT WORK? → LESSON
         ↳ FUMBLE CHECK
         ↳ PRACTICE
         ↳ PROFILE (Pro, from repeated outcomes)
```

The AI chooses the situation type. There is no mode picker.

Layers:

```
SwiftUI Views
    ↓
AppModel (session, navigation, loading, errors)
    ↓
Protocols: AI · OCR · ImageValidator · Store · Entitlements · Analytics
    ↓
Implementations (mock AI default, Vision OCR, disk store, UserDefaults entitlements)
```

Views never call an LLM or Vision directly. They never parse prose.

## 2. User flows

1. **First launch** — one onboarding screen → Home.
2. **Screenshot** — pick image → validate → OCR → review/edit text → analyze → Move.
3. **Typed** — compose → analyze → Move.
4. **Example chip** — fills compose → user taps analyze.
5. **Fumble Check** — paste draft → verdict → copy improved text. Gated Pro.
6. **Practice** — role-play → scorecard → try again. Gated Pro.
7. **Paywall** — shown when a gated action is requested. Home shows UNLOCK PRO when free analyses are gone.
8. **Settings** — privacy, delete local data, Pro preview (until StoreKit is live).
9. **Relaunch** — last sufficient analysis restores onto Home as LAST MOVE (free and Pro). History list stays Pro. Outcomes restore with the record.

Cancelled picker returns to Home with no error.

## 3. Screens

| Screen | Job | Next action |
| --- | --- | --- |
| Onboarding | Name the product in one beat | GET IN |
| Home | Answer “what now?” | Screenshot, type, example, or reopen LAST MOVE |
| Compose | Capture the situation | ANALYZE (disabled while empty) |
| OCR Review | Fix extracted text | ANALYZE or type instead |
| Loading | Branded copy, not a spinner-only void | (wait / cancel) |
| Analysis / Your Move | MOVE + SAY THIS or HOLD THIS + edge + DO THIS | Sticky FUMBLE / PRACTICE / DONE |
| Profile | Why a pattern was inferred | Back |
| Fumble Check | Strategic send/no-send | COPY / FIX |
| Practice | Run the conversation | THAT'S ENOUGH / TRY AGAIN |
| Scorecard | How they did | TRY AGAIN / DONE |
| Paywall | Why Pro | PREVIEW PRO / NOT NOW |
| Settings | Privacy and data | Delete / Pro preview |

## 4. Components (design system)

`HUTheme` color, type, space, radius.
`HUButton` primary / secondary / ghost, with press opacity and disabled state.
`HUCard`, `HUBadge`, `HUSectionHeader`, `HUStickyBar`.
`HULoadingView` cycling microcopy.
`HUErrorView` human copy + recovery button.
`HUEmptyState`.
`MoveHero` — the only oversized word on the result screen.

## 5. Data models

- `AnalysisRequest` — source, text, optional OCR confidence. No image.
- `SituationAnalysis` — situation, edges, shared interest, risks, facts/assumptions/unknowns, intent, move, options, reason, actions, responses, confidence, category.
- `MoveVerb` — COUNTER, WAIT, ASK, SEND, WALK.
- `MoveOption` — alternative strategy (purpose / risk / upside / execution). Display-only.
- `SituationIntent` — negotiate, extractInfo, reply, repair, decline, exit, unknown.
- `SituationCategory` — negotiation, conflict, reply, offer, request, decline, other.
- `OCRResult` — raw, cleaned, confidence, truncated flag.
- `FumbleCheckResult` — fumble / sendIt / tighten + headline + reason + optional rewrite.
- `PracticeSession` / `PracticeTurn` / `PracticeScorecard`.
- `StoredAnalysis` — id, dates, request, analysis, optional outcome. **Never stores image bytes.**
- `MoveOutcome` — YES / NO / PARTLY / NOT SURE plus a lesson template.
- `ProfileObservation` — count-based notes from ≥2 matching move+result pairs.
- `AppError` — typed failures with recovery.

## 6. AI pipeline

```
AnalysisRequest
    → PromptShield (user text is data, not instructions)
    → ContextGate
    → IntentDetector
    → SituationInterpreter (category, evidence, edges, risk, move)
    → MoveSelector (recommended + 2 alts)
    → AIServicing.analyze  (mock = interpreter; live = JSON)
    → AIResponseParser + enrich
    → SituationAnalysis.validated()
    → UI (MOVE hero, compact edge map, IF NOT THIS)
```

Default: `MockAIService` (deterministic, brand voice, injectable delay).
Optional: `LiveAIService` if `HUSTLEUP_AI_URL` is set. No API keys in source.

Failures the parser must handle: missing fields, unknown move, wrapped JSON, empty situation, non-JSON.

The mock **never invents market numbers**. Negotiation copy labels uncertainty as unknown/assumption.

## 7. OCR pipeline

```
PhotosPicker (no library permission)
    → Data
    → ImageValidator (size, decode, near-empty)
    → downscale for OCR
    → Vision VNRecognizeTextRequest (accurate, language detection)
    → sort observations top-to-bottom
    → TextCleaner
    → OCRResult
    → user edit if uncertain or empty
```

Images stay in memory. Temp files are not used. Failures become `AppError`, never crashes.

## 8. Networking

Only `LiveAIService` uses `URLSession`. Timeout 30s. Maps HTTP 429 → rate limited, 5xx → unavailable, transport errors → network/timeout. Request body is `{ task, input }` — no screenshot bytes.

MVP ships with networking **off** unless the env URL is present.

## 9. Persistence

`AnalysisStore`: JSON file in Application Support. Cap 20 records. Settings can wipe it.

UserDefaults (app suite): onboarding flag, analysis count, Pro preview flag.

No screenshot cache. No conversation analytics payload.

## 10. Error handling

All user-facing failures are `AppError`. Each has:

- short human title
- recovery suggestion
- primary recovery action (retry, type instead, open settings, dismiss)

Unknown errors collapse to a generic recoverable state without leaking internals.

## 11. Subscription architecture

`EntitlementProviding` is the only gate.

| Feature | Free | Pro |
| --- | --- | --- |
| Analysis | 3 | Unlimited |
| Fumble Check | Paywall | Yes |
| Practice | Paywall | Yes |
| History list | Hidden | Yes |
| Last MOVE card on Home | Latest sufficient result | Same |
| Advanced sections already in the model | Shown simply | Same MVP model (no second AI pass yet) |

StoreKit is **not** wired. `EntitlementStore` can flip Pro for development and UI tests. Paywall UI exists so the real store can replace the preview toggle later. The last sufficient result restores from the on-device history file on launch; the full RECENT list stays Pro.

## 12. Privacy boundaries

| Lane | Allowed | Forbidden |
| --- | --- | --- |
| Product analytics | event name, source, category, move verb, success/fail code | message text, screenshot, OCR text |
| AI content | in-memory + optional live POST of text | logging, analytics, disk images |
| Personal data | on-device history JSON | debug `print` of payloads |

`HULog` accepts static strings only. Parser tests use fixtures, not user data.

## 13. Testing strategy

- **Unit:** parser, cleaner, validator, entitlements, mock routing, store, fumble/practice models.
- **Integration:** AppModel analysis/OCR/error/paywall with injected fakes.
- **UI:** home, compose, analysis hero, last-move persist/reopen, example chip, empty ANALYZE disabled, paywall, practice, AI failure, onboarding skip.
- **Manual on simulator:** screenshot picker cancel, dynamic type, landscape iPad sanity.

Launch arguments: `-ui-testing`, `-skip-onboarding`, `-pro`, `-ai-fail`, `-ai-timeout`, `-ai-malformed`, `-fresh-install`.

## 14. Accessibility

Dynamic Type on all copy (hero uses `largeTitle` + minimum scale, not a hardcoded 48pt that cannot grow).
Buttons are `Button`s, 44pt min.
VoiceOver labels on icon-only controls.
Reduce Motion disables looping load animation.
Contrast: near-black + warm off-white + gold; danger/go used only for fumble verdicts.

## 15. Analytics events

`app_open`, `screenshot_selected`, `analysis_started`, `analysis_completed`, `analysis_failed`, `move_viewed`, `fumble_check_started`, `fumble_detected`, `practice_started`, `practice_completed`, `outcome_recorded` (move + yes/no/partly/notSure only), `paywall_viewed`, `subscription_started` (preview toggle counts as started for funnel testing).

## 16. Future extensibility (not MVP)

Voice input, live StoreKit, real provider accounts, widgets, share extension, multiplayer, localization beyond English UI strings (String Catalog ready), server-side market data, personalization memory.

---

## Dependency order

```
Theme + models + AppError
    → parser + text cleaner + image validator        [test]
    → entitlements + analytics + store               [test]
    → AI + OCR protocols and mock/fail doubles       [test]
    → AppEnvironment + AppModel                      [test]
    → Design system components
    → Home + Compose + OCR Review + Loading + Errors
    → Analysis / Move
    → Fumble + Practice + Paywall + Settings + Onboarding
    → UI tests + regression
```

| Work | Independent? | Must mock | Test before next |
| --- | --- | --- | --- |
| Models/parser | Yes | JSON fixtures | Yes |
| OCR/validator | Yes | Synthetic images | Yes |
| Entitlements | Yes | UserDefaults suite | Yes |
| Mock AI | Needs models | — | Yes |
| AppModel | Needs all protocols | All services | Yes |
| Screens | Needs AppModel + theme | AI/OCR | UI tests after unit |

## Mock vs live

| Service | MVP default | Swap point |
| --- | --- | --- |
| AI | `MockAIService` | `AIServicing` |
| OCR | `VisionOCRService` | `OCRServicing` |
| Entitlements | `EntitlementStore` | `EntitlementProviding` |
| Analytics | `InMemoryAnalytics` | `AnalyticsTracking` |
| Store | `FileAnalysisStore` | `AnalysisStoring` |
