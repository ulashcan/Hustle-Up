# Security assumptions

## What the client stores

- On-device JSON history of analyses (text + structured result). **No screenshot bytes.**
- UserDefaults: onboarding flag, free-analysis count, Pro preview flag.

## What never ships in the binary

- API keys, tokens, `.p8`, `.env` secrets.

## Live AI (optional)

`HUSTLEUP_AI_URL` is read from the **process environment at runtime**, not from Info.plist.

If a key is required, `HUSTLEUP_AI_KEY` is also environment-only and sent as `Authorization: Bearer …`. That is a **dev/server contract**, not an App Store secret store. A production app should not embed provider keys in the client. The hosted backend should authenticate the app.

Request body is `{ task, text, source, message?, session? }`. Screenshots are never uploaded.

## Analytics

`AnalyticsParameters` has no message/screenshot fields. `HULog` accepts `StaticString` only.

## Failure mode

AI/OCR/network failures become `AppError`. They must not crash the process.
