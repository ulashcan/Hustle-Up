# StoreKit (not live)

Billing is **not** production-ready.

## Product IDs (reserved)

| Product ID | Period | Unlocks |
| --- | --- | --- |
| `com.hustleup.pro.monthly` | monthly | analysis, fumbleCheck, practice, history, advancedAnalysis |
| `com.hustleup.pro.yearly` | yearly | same |

Mapping lives in `ProductCatalog`. Entitlement checks go only through `EntitlementProviding`.

## Current client behavior

- Free: 3 analyses.
- Pro preview toggle in Settings is a **development stand-in**.
- Paywall CTA “PREVIEW PRO” grants local Pro. It is not a purchase.
- `UnimplementedStore` fails closed. No silent unlock.

## Before claiming paid launch

1. App Store Connect products with those IDs
2. StoreKit 2 purchase + restore on a signed team
3. Receipt / entitlement sync replacing the preview flag
4. Real-device test of interrupt, fail, and restore

Until then: do not tell users they can buy Pro in the app.
