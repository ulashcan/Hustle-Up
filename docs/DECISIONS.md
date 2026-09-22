# Decisions (MVP)

Chosen without blocking. Revisit only if a real user or App Review forces it.

1. **Native SwiftUI iOS app, iOS 18+, Swift 6.** Matches the spec. No React Native, no web wrapper.
2. **MVVM-ish: one `AppModel` session object + protocol services.** Enough for MVP; not a full TCA graph.
3. **Default AI is mock, behind `AIServicing`.** No backend exists. Live URL is opt-in via environment.
4. **OCR is on-device Vision.** Privacy-first; no cloud OCR.
5. **PhotosPicker only.** No camera and no full photo-library permission.
6. **Accent is ember gold on near-black.** One accent. Not purple-AI, not rainbow.
7. **Move verbs are a closed set:** COUNTER, WAIT, ASK, SEND, WALK. Aliases (HOLD, CLARIFY, PUSH, ACCEPT, DECLINE, FOLLOW UP, STOP) map into that set. Unknown model output maps to ASK and drops confidence.
8. **Free = 3 analyses. Fumble + Practice are Pro.** History list is Pro. Current result stays visible for the session either way.
9. **StoreKit not included.** Paywall + `EntitlementProviding` are the seam. Settings “Pro preview” is clearly a stand-in.
10. **No git commits** unless asked. `.gitignore` is still added so the tree is App-Store-shaped.
11. **English UI strings in a String Catalog** so localization is possible later without string hunt.
12. **No invented market comps.** Negotiation unknown fields stay labeled unknown.
13. **Tests use Swift Testing** for unit/integration; XCTest for UI tests.
14. **Bundle ID:** `com.hustleup.app`. Display name: `HUSTLE UP`.
15. **Move options are display-only.** One recommended MOVE. Two alternatives under IF NOT THIS. Tapping an alt does not change the analysis.
16. **User/screenshot text is data.** Instruction-like sentences are stripped before reasoning (PromptShield). They must not force a verb.
17. **Outcomes are enums, not diaries.** DID IT WORK is free, and it lives on Home after the user leaves — not on the analysis screen before they've acted.
18. **Fumble Check is the primary post-MOVE action.** Practice is secondary. Routes are unique on the stack.
19. **Empty OCR is a review screen, not an error banner.** TYPE IT INSTEAD is the primary action. The overlay would cover it.
20. **WAIT copy is HOLD THIS.** If the line starts with “(Don't send.)”, it is not SAY THIS and it is not copyable.
