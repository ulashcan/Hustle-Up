# QA Audit — Execute loop (2026-09-17)

Tightened the core path: MOVE → copy/fumble → act → Home DID IT WORK.

## This pass

1. **Empty OCR has no error banner.** The review screen is the recovery. TYPE IT INSTEAD stays tappable.
2. **WAIT is HOLD THIS.** Unsendable lines are not titled SAY THIS and have no COPY.
3. **SAY THIS sits under the MOVE** so the line they can use is first.
4. **SEND IT copies the draft.** A verdict without a rewrite still has a COPY action.
5. **“adjusting” is not a hedge.** Word-boundary matching for `just` / `sorry` / `maybe`.
6. **DID IT WORK stays Home-only.** FUMBLE CHECK stays the primary sticky action.

## Still not launch-ready

Mock AI, no StoreKit, OCR simulator-only.
