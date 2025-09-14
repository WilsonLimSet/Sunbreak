# Sunbreak – Claude‑ready iOS Technical Spec (v0.2)

> **Goal:** Ship an iOS app that restricts selected apps during bedtime and only unlocks them after a *daylight* verification (quick sky photo). Monetize with a 14‑day free trial, then paid subscription.

---

## 1) Scope & Targets

* **Platforms:** iPhone (iOS 17+; Swift 5.10; Xcode 15+).
* **Languages:** Swift + SwiftUI.
* **Frameworks:** `FamilyControls`, `ManagedSettings`, `DeviceActivity` (aka Screen Time API set), `StoreKit 2`, `AVFoundation` (camera), `CoreLocation` (coarse), `BackgroundTasks` (fallback unlock expiry), `SwiftData` or `CoreData` for persistence.
* **App Architecture:** Main app + `DeviceActivityMonitorExtension` target.
* **Entitlements (Apple‑approved):** `com.apple.developer.family-controls` for *all* targets that use Screen Time APIs (main app + extension). Add App Groups for shared state.

---

## 2) Key Product Flows

### A. Onboarding

1. Welcome → purpose & privacy summary.
2. Request *individual* Screen Time authorization via `AuthorizationCenter`.
3. Present `FamilyActivityPicker` to choose apps/categories/web domains to control.
4. Ask for **coarse** location (one‑time) to compute sunrise/sunset (fallback); deny path supported.
5. Pick bedtime & wake time.

**Acceptance:** Permissions handled gracefully; denial paths continue with reduced features; selections persisted.

### B. Bedtime Blocking

* Compute user's nightly window (bed → wake). During this window:

  * Apply **shields** to the selection via `ManagedSettingsStore`.
  * `DeviceActivityMonitorExtension` observes launches (attempted opens) and supplies a custom Shield UI message (SwiftUI view) with CTA: "Unlock after daylight."

**Acceptance:** Selected apps are blocked; Shield view appears consistently; categories respected.

### C. Daylight Unlock (Day‑long, no TTL)

* When the user taps "Unlock," present a capture flow during **daylight hours**.
* **Policy:** One successful daylight verification **unlocks for the rest of the day** (until the next bedtime). No 30‑minute timer.
* **Flow:** On or after civil sunrise (or user wake time, whichever is later), the first attempt to use a restricted app or the in‑app "Start Day" button triggers the photo verification. After success, all selected apps remain unshielded until the next bedtime boundary.
* **Failure:** If attempted before sunrise or verification fails (e.g., indoor/night shot), explain why and prevent unlock. Users can retry later in daylight.

**Acceptance:** Unlock never succeeds before sunrise; once verified in daytime, selected apps remain fully available until the next bedtime; at bedtime the shield re‑applies automatically.

---

## 3) Technical Design

### 3.1 Screen Time APIs (Correct Data Model)

* Persist **`FamilyActivitySelection`** (opaque tokens), **not** raw bundle IDs.
* Use `ManagedSettingsStore` to *shield* `applications`, `categories`, and `webDomains` from the saved selection.
* Use `DeviceActivityCenter` to monitor activity and host a `DeviceActivityMonitorExtension` that can react to attempted access (to show a custom Shield view with guidance).

**Notes**

* Some `Application.bundleIdentifier` values are only available *inside the extension*; outside, they may be `nil`. Treat tokens as primary identifiers.
* All Screen Time APIs are privacy‑preserving; never export usage out of the device.

### 3.2 Shields & Daily Unlocks

* During bedtime window: `store.shield.applications = selection.applicationTokens` (plus categories/domains as needed).

* **Day‑long unlock:**

  * Maintain `dayUnlockedFor` (e.g., `DateComponents(year:month:day)`) in App Group.
  * When daylight verification passes, set `dayUnlockedFor = today` and **clear shields** for the selection.
  * On every relevant lifecycle event (app foreground, extension callbacks, schedule ticks), if `today == dayUnlockedFor` **and** now is outside bedtime, keep shields cleared; otherwise apply shields.
  * At the next bedtime boundary, **reset** `dayUnlockedFor` and apply shields.

* **Scheduling:** Use `DeviceActivitySchedule` to represent bedtime→wake periods so your monitor extension receives reliable callbacks at boundaries. A lightweight watchdog (e.g., periodic schedule slices) can help recover from missed events.

### 3.3 Daylight Verification (Hybrid)

* **On‑device:**

  * Live capture via `AVCaptureSession` (no gallery). Compute brightness/blue‑sky ratio and optional sky segmentation; require liveness cue; enforce `now ≥ civil sunrise`.
* **Cloud fallback (optional):** Only when heuristic is *ambiguous*, call a low‑cost VLM once; hard cap invocations/day.
* **Trigger points:** First open of a restricted app after wake/sunrise, or explicit "Start Day" in the app.

Daylight Verification (Hybrid)

* **On‑device:**

  * Live capture via `AVCaptureSession` (disable gallery). Extract frame, compute brightness & blue‑sky ratio; optional sky segmentation (Core ML lightweight model, e.g., MobileNet‑based DeepLab subset) to ensure sky pixels ≥ threshold; sanity check that shutter occurred outdoors (fast exposure, high ambient lux via `AVCaptureDevice`.)
  * Enforce real‑time capture (no EXIF from library), random liveness pose cue, and
    ensure device time ≥ civil sunrise for current coarse location.
* **Cloud fallback (optional):** If heuristics *ambiguous*, call a cheap VLM once with prompt like: "Binary answer: Does this **freshly captured** photo show an **outdoor daytime sky**?"
* Cache recent success to avoid re‑billing; cap to N fallbacks/day.

### 3.4 Sunrise/Sunset Logic

* With user consent, one‑time coarse `CLLocation` to infer timezone & lat/long; compute civil sunrise/sunset locally (e.g., NOAA algorithm) or via a tiny table. If denied, let the user select a city or assume device timezone + fixed sunrise 7:00 AM (configurable).

### 3.5 Persistence

* `SwiftData` models:

  * `UserPreferences { bedtime, waketime, daylightPolicy, … }`
  * `SelectionRecord { FamilyActivitySelection, createdAt }`
  * `EntitlementState { isAuthorized, lastChecked }`
  * `UnlockState { unlockUntil, lastSuccessAt }` in App Group for extension.

### 3.6 Error & Edge Handling

* Screen Time auth revoked → show blocking banner and retry affordance.
* No camera / denied → fallback to sunrise‑only unlock (time‑based), clearly disclosed.
* Flight / polar latitudes → allow manual city override.
* Offline → on‑device checks only; queue cloud calls until back online (but not needed for unlock).

---

## 4) Monetization & Trials (StoreKit 2)

* **Products:** `sunbreak.monthly`, `sunbreak.annual` in one Subscription Group.
* **Intro offer:** 14‑day **free** for both products; show eligibility via `Product.SubscriptionInfo.Status`.
* **Paywall Triggers:** Onboarding complete, end of trial, or when trying to run Daylight Unlock without entitlement.
* **Receipts:** Local verification via StoreKit 2; consider App Store Server Notifications for server analytics later.

---

## 5) Security & Privacy

* No export of Screen Time data; no analytics on app usage items; tokens remain on device.
* Camera frames evaluated in‑memory; nothing persisted unless user opts into debug reporting.
* If enabling cloud VLM fallback: transmit only a downscaled, anonymized frame; document in Privacy Policy; allow user to opt out.
* Fill App Privacy Nutrition labels accurately; add `PrivacyInfo.xcprivacy`; declare required‑reason APIs.

---

## 6) UI/UX Requirements

* Clean, single‑purpose flows; dark‑friendly.
* **Screens:** Onboarding, Picker, Schedule, Daylight Unlock, Paywall, Settings (Data & Privacy), About.
* **Copy:** Firm but encouraging; clarify that bypass attempts are counter‑productive.
* **Accessibility:** VoiceOver labels; dynamic type; haptics for success/fail.

---

## 7) Implementation Tasks (Claude‑sized)

1. Project setup: App + Monitor Extension + App Group + entitlements files.
2. Authorization manager with async `requestAuthorization(for: .individual)` and state machine.
3. Picker screen binding to `FamilyActivitySelection`; serialize selection.
4. Bed/Wake scheduler; compute next windows; apply shields.
5. Monitor extension: custom Shield view + callback plumbing.
6. Daylight capture view with liveness cue; implement Tier‑1 checks; stub Tier‑2 API client.
7. Day‑long unlock flow: set/clear shields based on `dayUnlockedFor` and bedtime boundaries.
8. StoreKit 2 paywall (trial), eligibility UI, restore.
9. Persistence via SwiftData + App Group bridge.
10. Unit tests for schedule math; UI tests for picker and shields; integration smoke tests on two physical devices.

---

## 8) Non‑Goals (v1)

* iPad, Mac, Family‑guardian mode, web filters, VPN‑level blocking.
* Detailed Screen Time analytics/graphs.

---

## 9) Pseudocode & Snippets

### Auth & Picker

```swift
import FamilyControls

@MainActor
final class ScreenTimeAuth: ObservableObject {
  @Published var status: AuthorizationStatus = .notDetermined
  func request() async {
    do {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      status = AuthorizationCenter.shared.authorizationStatus
    } catch { status = .denied }
  }
}

struct PickerView: View {
  @State private var selection = FamilyActivitySelection()
  var body: some View {
    Button("Select apps to limit") { showingPicker = true }
    .familyActivityPicker(isPresented: $showingPicker, selection: $selection)
  }
}
```

### Apply Shields

```swift
import ManagedSettings

let store = ManagedSettingsStore()
func applyBedtimeShields(from selection: FamilyActivitySelection) {
  store.shield.applications = selection.applicationTokens
  store.shield.applicationCategories = .specific(selection.categoryTokens)
  store.dateAndTime.requireAutomaticDateAndTime = true // optional nudge
}

func clearShields() { store.shield.applications = nil; store.shield.applicationCategories = nil }
```

### Monitor Extension sketch

```swift
// DeviceActivityMonitorExtension target
import DeviceActivity
import ManagedSettings

final class Monitor: DeviceActivityMonitor {
  override func intervalDidStart(for activity: DeviceActivityName) { /* apply shields */ }
  override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
    // user attempted to open a shielded app → keep shields & surface UI
  }
}
```

### Daylight Heuristic (very high level)

```swift
struct DaylightResult { let ok: Bool; let reason: String }
func isDaylight(_ pixelBuffer: CVPixelBuffer, now: Date, sunrise: Date) -> DaylightResult {
  guard now >= sunrise else { return .init(ok:false, reason:"before sunrise") }
  // brightness & blue ratio checks, optional sky segmentation…
  return .init(ok: score > 0.7, reason: score > 0.7 ? "ok" : "ambiguous")
}
```

---

## 10) Open Questions for Review

* Exact minimum iOS (16.4 vs 17) based on device share.
* Keep Tier‑2 cloud fallback in v1 or ship on‑device only?
* Duration presets besides 30‑min (e.g., 10 / 25 / 45 min)?
* Localized languages for launch (EN‑US + EN‑SG initially).

---

## 11) App Store Notes (for submission)

* Purpose strings (camera, location) clearly explain the daylight requirement & privacy.
* In‑app "Why blocked?" page linked from Shield; transparent about limitations.
* Support URL and Privacy Policy ready; include contact email.
* Screenshots show picker, schedule, shield, daylight unlock, paywall.

---

## 12) Definition of Done (v1)

* End‑to‑end flow works on two test devices (fresh install) with entitlement enabled.
* 95% success/false‑positive target for daylight check in bright conditions; zero unlocks before sunrise in normal usage.
* Trial → paid path verified in Sandbox across eligible/ineligible accounts.
* No crashes, ANR < 0.1%, battery impact < 3%/day idle.