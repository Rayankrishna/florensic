# Backend integration — status

Implements [`frontend-integration-guide.md`](frontend-integration-guide.md).
The app talks to the Florensic API by default and keeps the mock repositories
behind a flag for demos, goldens and tests.

## Running

```sh
# Against the local stack (Android emulator reaches the host on 10.0.2.2)
flutter run

# Against a deployed API
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

There is no mock build. `lib/` talks to the API and nothing else; the only
fixtures left live under `test/support/fakes/` and are injected through
`setupLocator(repositories: …)` so the suite can assert designed behaviour
without a backend.

## Layout

Follows the lead app's shape (`HttpClient` + providers), extended with
repository implementations so `lib/screens/` and `lib/stores/` were left
almost untouched.

| File | Role |
|---|---|
| `lib/domain/core/services_config.dart` | `HttpClient`: Dio, `Bearer`, one silent refresh on `token_expired`, error envelope → `ApiException(message, code:)`, existing `ApiInterceptor` chain. Global `http` handle. |
| `lib/domain/core/token_store.dart` | Token pair in `flutter_secure_storage` (keychain / keystore), not SharedPreferences. Refresh rotation handled. |
| `lib/domain/core/json.dart` | Forgiving readers — an unknown field never crashes a screen. |
| `lib/domain/provider/*.provider.dart` | One provider per API area: `auth`, `plants`, `species`, `photos`, `insights`. |
| `lib/domain/repositories/remote/*.dart` | Real implementations of the existing repository interfaces. |
| `lib/shared/services/capture_service.dart` | Camera, gallery and location behind one type. `StubCaptureService` is test-only. |

## Wired

- **Auth** — email only: sign-in, sign-up → OTP, OTP verify, password reset,
  sign-out, session restore via `GET /v1/me`, token refresh with rotation,
  and a clean sign-out when a session cannot be rescued.
- **Plants** — list, create (with the identification `photo_id`), delete with
  `keep_photos`, water, resume, schedule/reminders, history, care events,
  today's tasks and completion.
- **Species** — paged catalogue, detail, featured, plus `suggest` / `resolve`
  for the search-to-correct path (`SpeciesProvider`).
- **Identification** — capture → `POST /v1/photos` → poll
  `GET /v1/analysis/{job_id}` → result with confidence, rationale and
  alternatives; `no_confident_match` raises the app's existing
  `NoConfidentMatch`.
- **Check-in** — capture → upload (`purpose=checkin`) → `POST
  /v1/plants/{id}/condition-updates` → poll → the rebuilt plant.
  `ConditionUpdate` now also carries `model_verdict`,
  `verdict_disagreement` and `score_before/after`.
- **Insights** — daily items and the humidity correlation, with
  `meta.attribution` exposed for display.
- **Camera** — real capture on device: permissions via `permission_handler`,
  photos re-encoded to stay inside the 12 MB limit, optional coordinates
  attached, and a Settings route out of a permanent denial.

## No endpoint yet (§7) — shown as unavailable, never faked

- **Weather card** — `loadWeather()` returns `null`; Insights shows a
  "Live weather is on the way" panel and the home card drops its stat row.
- **Environment history** — returns empty; the chart is replaced by a short
  explanatory card.
- **Notifications** — `UnavailableNotificationsRepository` returns nothing and
  the screen renders its designed empty state.

Each is a one-line swap in the locator when the endpoint lands.

## Not done

- **Google / Apple sign-in is deliberately absent.** The API exposes
  `/v1/auth/oauth/{google|apple}`, but it needs the platform SDKs to mint an
  `id_token`. The buttons, the store action, the provider method and the brand
  glyphs have all been removed — the app signs in with email and OTP only.
- **iOS** has no target in this repo. When one is added, `Info.plist` needs
  `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` and
  `NSLocationWhenInUseUsageDescription`, plus an ATS exception if the API is
  reached over plain http.
- **Care-plan screen** (`GET /v1/plants/{id}/care-plan`) — the provider method
  exists; the screen does not.
- Push delivery, community, user time zones — backend M4 or later.
