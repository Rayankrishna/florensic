# Integrating the Florensic backend into the Flutter app (`Rayankrishna/florensic`)

_**Updated 2026-10-05 for the health-score cutover (see [`CHANGELOG.md`](../CHANGELOG.md))**; first Already integrated against the September version? Read [`frontend-upgrade-guide.md`](frontend-upgrade-guide.md) first: it lists only what changed.
written 2026-09-24. For the frontend developer and the coding assistant working in the Flutter
repo. Backend contract: [`docs/openapi.json`](openapi.json) (authoritative),
[`docs/frontend-api-guide.md`](frontend-api-guide.md) (every endpoint, shape and error),
Postman: [`docs/postman/`](postman/). Copy this file into the Flutter repo as
`docs/backend-integration.md` and link it from its `CLAUDE.md`/`README.md` so an assistant
working there reads it first._

The Flutter app (commit `6ee19c6`, 99 Dart files) is complete against **mock repositories**:
every screen calls an abstract repository, every repository calls `MockApiClient.send(path, body)`,
and `lib/locator.dart` wires the mocks. The backend is live and mirrors those repositories
closely. Integration is therefore mechanical: one HTTP client, one real implementation per
repository interface, `fromJson` on each model, secure token storage, and photo capture. Nothing
in `lib/screens/` or `lib/stores/` needs to change except where a feature was faked (photo
capture, species search) or where the backend deliberately differs (§4).

---

## 1. Where things go in the Flutter repo

| Frontend file (exists) | What to do |
|---|---|
| `lib/locator.dart` | Swap each `Mock*Repository(client)` for the real one (§3). Register one `ApiClient` (HTTP) instead of `MockApiClient`. Keep the mock wiring behind a `--dart-define=USE_MOCKS=true` flag for goldens/tests. |
| `lib/domain/repositories/mock/mock_api_client.dart` | Keep for tests. Add `lib/data/api_client.dart`: an HTTP client that runs the existing `ApiInterceptor` chain (`LoggingInterceptor` stays; drop `LatencyInterceptor` for real calls), adds `Authorization: Bearer`, refreshes on 401, and turns the backend error envelope into `ApiException(message)` (§6). |
| `lib/interceptors/api_interceptor.dart` | Unchanged. `ApiException` already exists; add `code` to it (`ApiException(this.message, {this.code})`) so stores can branch on stable codes. |
| `lib/domain/repositories/*_repository.dart` | Interfaces stay as they are. Add `lib/data/*_repository_impl.dart` (or `remote/`) implementing each against the endpoints in §3. |
| `lib/domain/models/*.dart` | Add `fromJson` factories (none exist today). Field mapping in §5. Where the app has a field the backend lacks (`glyph`, `ground`, `isNew`) keep the app's default. |
| `lib/storage_manager.dart`, `lib/key.dart` | Store `access_token`/`refresh_token` in **`flutter_secure_storage`**, not SharedPreferences; keep `pg.auth.token` only as a "signed-in" flag if the shell relies on it. |
| `lib/stores/scanning_store.dart` | Today `identify(framing: target.name)` is called with no image. Add capture (`image_picker` or `camera`) and location (`geolocator`, optional), then follow §3.2 (upload → poll). |
| `lib/stores/condition_update_store.dart` | Add the photo step: the check-in is a photo plus the verdict/observations/note the store already collects (§3.4). |
| `pubspec.yaml` | Add: `dio` (or `http`), `flutter_secure_storage`, `image_picker`, `geolocator`, `permission_handler`. `mobx`/`get_it` stay. |
| Android/iOS manifests | Camera, photo library and location permissions (the `PermissionsStore` UI already exists; wire it to `permission_handler`). |

Base URL: `http://localhost:8010` for the local stack (Android emulator: `http://10.0.2.2:8010`);
the shared server URL will be added here when deployed. All routes are under `/v1`.

---

## 2. Conventions the client must implement once

- **Auth header** `Authorization: Bearer <access_token>`. Access token lives 15 min
  (`expires_in: 900`), refresh token 30 days and **rotates** on every `POST /v1/auth/refresh`
  — store the new pair, discard the old. A 401 `token_expired` → refresh once and retry the
  request; 401 `token_reused`/`invalid_token` → sign out.
- **Error envelope** on every failure: `{"error": {"code": "...", "message": "..."}}` (422 adds
  `details`). Map to `ApiException(message, code: code)`. `message` is safe to show verbatim —
  that is what the app already does.
- **JSON** is `snake_case`; ids are UUID strings; timestamps ISO-8601 **UTC**; dates
  `YYYY-MM-DD`.
- **Days belong to the owner, not to UTC.** The profile carries an IANA `timezone` (default
  `"UTC"`); send the device zone once on first launch — `PATCH /v1/me {timezone}` (§3.1) — and
  the backend decides "today" from it. Every *date* the API answers with (today's task list, a
  watering's due date, a check-in window, an insight's `day`, a plan item's and a treatment
  step's `due_at`) is already a date on that calendar: parse it as a plain local date, never
  `DateTime.parse(d).toLocal()`. Timestamps (`*_at`) are still UTC instants and **do** convert.
  `meta.timezone` on the home feed, the insights feed and the care plan says which calendar
  that document is on. Upload/analysis quotas still reset on a UTC day.
- **Full plant on every mutation**: water, resume, schedule, patch, create, species correction all
  return the complete `Plant` — keep calling `replacePlant(updated)` exactly as the stores do now.
- **Async jobs**: photo analysis returns `202 {job_id}`; poll `GET /v1/analysis/{job_id}` every
  ~2 s until `state` ∈ `done | no_confident_match | failed`. Identification 10–60 s, check-in
  10–40 s. Show the existing "scanning" state meanwhile.
- **Rate limits**: auth 10/min/IP, public reads 60/min/IP (species, suggest — **debounce the
  typeahead ~300 ms**), OTP 5/hour/email → 429 `rate_limited`.
- **Location**: send `lat`/`lon` with photo uploads when permission is granted. The backend never
  returns coordinates; weather, the home area and insights depend on them.
- **Attribution**: wherever weather-driven text is shown (insights, care-plan rationale), display
  `meta.attribution` = `"Weather data by Open-Meteo.com (CC BY 4.0)"`.

---

## 3. Repository by repository

### 3.1 `AuthRepository`

| Interface method (unchanged) | Backend call | Notes |
|---|---|---|
| `signUp(name, email, password)` | `POST /v1/auth/sign-up {name,email,password}` → 202 | Sends an OTP; **no tokens yet**. The app already has a code screen (`requestCode`/`verifyCode`). |
| `verifyCode(email, code)` | `POST /v1/auth/otp/verify {email, code}` → 200 TokenPair | Store both tokens; `user` inside the response fills `UserProfile`; then `GET /v1/me` for stats. |
| `requestCode(email)` | `POST /v1/auth/otp/request {email, purpose: "signin"}` → 204 | Also `purpose: "reset"` for password reset (`POST /v1/auth/password/reset {email, code, new_password}`). |
| `signIn(email, password)` | `POST /v1/auth/sign-in` → 200 TokenPair | 403 `email_unverified` → go to the code screen. |
| `continueWithProvider(provider)` | `POST /v1/auth/oauth/google|apple {id_token, name?}` → 200 TokenPair | Needs the Google/Apple SDK to obtain `id_token`; dev stack accepts fixture tokens. |
| `signOut()` | `POST /v1/auth/sign-out {refresh_token?}` → 204 | Then clear secure storage. |
| session restore (`AuthStore` line ~150) | `GET /v1/me` | Replaces the hard-coded "Alex Moreau" profile. `Me` has `stats {plants_kept, under_active_care, average_health, care_streak_weeks}` — exactly `UserProfile`'s counters. |
| profile edits (today toasts) | `PATCH /v1/me {name?, city?, units?, reminder_time?, timezone?, consent_training?}` | `units` is `metric|imperial` (app shows `'°C · ml'`). |
| **first launch / zone change (new)** | `PATCH /v1/me {timezone}` | Send the device zone (`flutter_timezone`, an IANA name like `Asia/Kolkata`) right after the first successful token exchange, and again whenever it differs from `Me.timezone`. Everything dated depends on it; `422 invalid_timezone` if the name is not in the tz database. |
| push token | `PUT /v1/me/devices {platform, push_token}` → 204 | Stored only; **nothing is ever sent** (§7). |

### 3.2 `IdentificationRepository` — the scanning flow

`identify({framing})` becomes a three-step sequence inside the real implementation (the
interface can stay if it internally uploads and polls, or grow an `imagePath`/`lat`/`lon`
argument — the latter is cleaner):

```
1. POST /v1/photos (multipart)  file, purpose=identify, framing=leaf|whole_plant|flower,
   source=camera|gallery, lat?, lon?, location_accuracy_m?, captured_at?      → 202 {job_id, photo_id}
2. GET  /v1/analysis/{job_id} every ~2 s                                      → state done | no_confident_match | failed
3. Build IdentificationResult from the job:
      species      ← job.species (full Species; may be null on no_confident_match)
      confidence   ← job.confidence
      rationale    ← job.rationale
      alternatives ← job.alternatives[] {species|null, scientific_name, confidence}
   Keep photo_id — POST /v1/plants needs it.
```

- `framing` values: the app's `ScanTarget.wholePlant` → send `whole_plant` (snake_case).
- `state == "no_confident_match"` → throw the app's existing `NoConfidentMatch`, but keep
  `alternatives` and show the **species search** (§3.6) — the "not this?" path.
- `state == "failed"` → `ApiException(job.error)`; if `retryable`, offer retry.
- `initial_health {verdict, observations[], severity}` is also on the job — show it on the result
  card; it seeds the plant's first care plan.
- Upload limits: JPEG/PNG/HEIC ≤ 12 MB, short side ≥ 480 px (413 `payload_too_large`); daily caps
  → 429 `upload_quota_exceeded` / `analysis_quota_exceeded`.

### 3.3 `PlantRepository`

| Interface method | Backend call |
|---|---|
| `loadPlants()` | `GET /v1/plants` → `Plant[]` |
| `addPlant(species, nickname?)` | `POST /v1/plants {species_id, photo_id?, nickname?, room?, indoor?}` → 201 Plant. Pass the identify `photo_id` so the photo, its location and the first care plan attach. |
| `removePlant(id)` | `DELETE /v1/plants/{id}?keep_photos=true` → 204 (the app's "keep photos" toggle maps to this query). |
| `loadTodaysCare()` | `GET /v1/care/today` → `CareTask[]` — **four** `kind`s now, see below |
| `completeTask(taskId)` | `POST /v1/care/tasks/{client_id}/complete` → CareTask (a watering task waters the plant). |
| skip a step (new) | `POST /v1/care/tasks/{client_id}/skip {reason?}` → CareTask — **`treatment_step` only**; anything else is `400 task_not_skippable`, an id not on today's list is `404 task_not_found`. `reason` ≤ 200 chars. The task leaves the list (`done: true`); the step itself becomes `skipped` and still counts against `care_score`. |
| `markAsWatered(id)` | `POST /v1/plants/{id}/water {amount_ml?, at?}` → Plant (the score does **not** move) |
| skip a watering (new) | `POST /v1/plants/{id}/water/skip {reason}` → Plant. `soil_wet` counts as care given and pushes `next_watering` two days out; `away`/`forgot` change nothing — the watering stays due, only the event is recorded. `409 plant_not_active` on a paused plant. |
| quick note (new) | `POST /v1/plants/{id}/notes {chips[], text?}` → Plant. One to seven chips from `drooping · dry_soil · wet_soil · yellowing · leaf_drop · pests_seen · new_growth`, no repeats (anything else 422); `text` optional, ≤ 200 chars, never parsed. This is the no-camera answer — it pulls `schedule.check_in_window_opens` forward (≤ 2 days), sets `leaf_drop_reported` for `leaf_drop`, and does **not** move `health_score`. `409 plant_not_active` when paused; a `stale` plant takes notes normally. |
| treatment plans (new screen) | `GET /v1/plants/{id}/courses` → `Course[]`, newest first, closed ones included. **One plan per plant**, not one per problem: `problems[]` worst first, `steps[]` the whole plan in one order. Build the screen against this. |
| treatments (per problem) | `GET /v1/plants/{id}/treatments` → `Treatment[]`, newest first, closed ones included, steps in order. The same rows, ungrouped — keep it for "has this plant had thrips before?". |
| stop a treatment (new) | `POST /v1/treatments/{id}/abandon {reason, note?}` → Treatment. `reason` is `too_hard \| plant_recovered \| other` and is not cosmetic (`plant_recovered` closes it as a resolution); `note` ≤ 200. `409 treatment_not_open`, `404 treatment_not_found`. |
| stop a whole plan (new) | `POST /v1/courses/{id}/abandon {reason, note?}` → Course. The same three reasons, applied to every open problem in one transaction. `409 course_not_open`, `404 course_not_found`. |
| `resumeActiveCare(id)` | `POST /v1/plants/{id}/resume` → Plant (409 `plant_not_paused` on an active plant). |
| `setReminder(id, watering?, checkIn?)` | `PUT /v1/plants/{id}/schedule {watering_reminder?, check_in_reminder?, reminder_time?, frequency_days?, next_water_amount_ml?, check_in_interval_days?, check_in_window_days?}` → Plant — this also unlocks the schedule-editing sheet that is a toast today. |
| plant edits (toasts today) | `PATCH /v1/plants/{id} {nickname?, room?, indoor?, visibility?, light_status?, light_detail?}` → Plant |
| detail screen extras | `GET /v1/plants/{id}` (the **only** list-free place `risk` is computed — §4) · `GET /v1/plants/{id}/history?range=7d|30d|90d` (`TrendRange` week/month/quarter) · `GET /v1/plants/{id}/care-events` · `GET /v1/plants/{id}/photos` · `GET /v1/plants/{id}/care-plan` (new screen data, §4) · `GET /v1/plants/{id}/courses` |
| `submitConditionUpdate(...)` | see §3.4 |

**Today's four task kinds.** `CareTask.kind` is `watering | condition | treatment_step |
environment`, in one list; `id` is the client id you post back — `task-water-<plantId>`,
`task-cond-<plantId>`, `task-tstep-<stepId>`, `task-env-<plantId>-<YYYYMMDD>`. Switch on `kind`
and **tolerate a value you do not know** (render `title`/`detail`, allow complete). An
`environment` task is written by the hourly weather sweep (heat, cold, a dry run, dry air, a wet
week): its `title`/`detail` are the instruction for that plant's placement, so render them as
they are — completing only marks it done, it cannot be skipped, and it drops off on its own when
the day turns. A `treatment_step` is one due step of an open treatment plan, the only skippable kind; it carries
`course_id`, `problem_id` and `problem` so the list can be grouped by plan and labelled by
problem. `problem_id: "all"` (`problem: "All problems"`) is a step that serves every problem on
the plan — render it once, under the plan rather than under a problem. All three are `null` on
the other three kinds, and one plant's steps already arrive together in the plan's own order.

**The treatments screen** (new; nothing in the mocks). Build its top level out of
`GET /v1/plants/{id}/courses`: **a plant has one plan**, with one header (status, worst severity,
next review) and one ordered step list underneath, and the problems listed beside it. A step whose
`serves` is `"all"` belongs to the plan and not to any one problem. Underneath that, a treatment
is one problem plus the course
prescribed for it, opened automatically by identification or by a check-in that finds a problem.
Render the list as history: `status` is `active | improving | escalated | resolved | superseded |
abandoned`, `superseded_by_id` points at the course that replaced this one, and `abandon_reason`
says whether the owner stopped it or the plant got better. **Every check-in judges every open
treatment**, so refetch after one finishes — `status`, `tier`, `review_at` and `steps` will have
moved on their own. A step's `status` is `pending | done | skipped | superseded`, and `superseded`
is the *system* dropping a step rather than the owner failing one. Opening a treatment also
shortens `schedule.check_in_interval_days` without the owner touching anything.

### 3.4 Check-in (`ConditionUpdateStore.submit`) — two steps plus a poll

```
1. POST /v1/photos (multipart) purpose=checkin, plant_id=<id>, file, framing, source, lat?, lon?  → 202 {photo_id}
   (the job is created but does NOT run until step 2)
2. POST /v1/plants/{id}/condition-updates
        {photo_id, user_verdict: healthy|concerns|needs_attention, observations: [...], note}      → 202 {job_id}
3. GET  /v1/analysis/{job_id} every ~2 s (allow 3 min) → when done, read job.checkin:
        plant (full Plant → replacePlant; this one carries `risk`), update {id, plant_id, photo_id,
        user_verdict, model_verdict, verdict_disagreement, change_vs_last, new_growth, flowering,
        photo_quality, quality_issue, score_before, score_after, alpha, provisional,
        observations, note, created_at},
        score_delta, next_check_in, plan_revision_id
```

- `ConditionVerdict.needsAttention` → send `needs_attention`. The observation chips
  ("Yellowing leaves", …) go verbatim in `observations` (≤ 10 × 160 chars); `note` ≤ 1000.
- Errors on step 2: 404 `photo_not_found`, 400 `photo_wrong_purpose`, 409 `photo_already_used`
  (poll the existing job instead), 429 quota codes.
- Show `model_verdict` beside the user's verdict; `verdict_disagreement: true` means they differ
  by more than one band and the user's verdict was not counted. `score_after` can never exceed
  the ceiling of `model_verdict`: 100 healthy · 69 concerns · 39 needs_attention. If
  `plan_revision_id` is null the check-in still landed and the plant kept its previous plan.
- **`score_before` and `score_delta` can be `null`** on a plant's first scored check-in (nothing
  to blend into), and both scores are null on a check-in the new scorer never scored. Render the
  delta chip only when `score_delta != null`.
- `alpha` (0–1) is how much this photo was believed — the score moved `alpha ×` the distance to
  what the photo said. `provisional: true` means the photo was too poor to read and the number
  is held lightly (`photo_quality`, `quality_issue` say why); worth a "we could not see much —
  try another photo" hint, and the next usable photo is believed outright.
- `flowering` and `new_growth` feed the home feed's `changes` card. The treatments the reviewer
  judged and the quick-note reports it confirmed are **not** in this response: refetch
  `GET /v1/plants/{id}/courses` and the care plan after the job finishes. A check-in that finds a
  new problem **adds it to the open plan** rather than starting a second one, and leaves a
  `treatment_problem_added` care event, which is the owner's only notice.

### 3.5 `PokedexRepository`

| Interface method | Backend call |
|---|---|
| `loadCatalogue()` | `GET /v1/species?limit=100&cursor=` → `{items, total, next_cursor}` — **async and paged**; the synchronous `catalogueSize`/`plantOfTheWeek` getters must become async or be filled after the first load. `traits=indoor,low_light,beginner,pet_friendly` maps `PokedexFilter`. `q=` for the browse filter. |
| `speciesById(id)` | `GET /v1/species/{species_id}` → Species (ids are UUIDs, not `monstera-deliciosa` slugs; `number` is the catalogue number the Pokédex shows). |
| plant of the week | `GET /v1/species/featured` |

### 3.6 Species search — confirm or correct an identification (new, not in the mocks)

```
GET  /v1/species/suggest?q=<typed>&limit=8      (public; ≥ 2 chars; debounce 300 ms)
  → {query, items: [{source: catalogue|inaturalist, species_id|null, external_id|null,
                     scientific_name, common_name, matched_term}]}
POST /v1/species/resolve (auth)  {source, species_id?, external_id?, scientific_name, matched_term?}
  → 200 {species_id, created:false}  (known plant, instant)
  → 201 {species_id, created:true}   (new plant: ~10 s while a care baseline is drafted — show a spinner)
POST /v1/plants/{id}/species (auth) {species_id}  → 200 Plant   (correct an existing plant)
```

- Works with common names in any language ("tulsi", "money plant", "swiss cheese").
- `catalogue` rows already have a `species_id` → use it directly. `inaturalist` rows need
  `resolve` first. Only species are returned (never genus rows), so every row is selectable.
- Before the plant exists: suggest → (resolve) → `POST /v1/plants {species_id, photo_id}`.
  After: suggest → (resolve) → `POST /v1/plants/{id}/species` → `replacePlant`.
- Errors: 429 `species_draft_quota_exceeded` (5 new plants per user per day), 503
  `species_draft_unavailable` (try again shortly).

### 3.7 `InsightsRepository`

| Interface method | Backend today |
|---|---|
| `loadInsights()` | `GET /v1/insights` → `items[]` → `EnvironmentalInsight {id, title←headline, body, kind}`. Kinds: `heat`, `low_humidity` (→ app `humidity`), `rain`, `low_light_season` (→ app `light`). `plant_ids[]`, `tone` (`calm|heads_up|urgent`) and `data` are extra. `isNew` = `day == today`. |
| `loadCorrelation()` | same response, `correlation {humid_weeks, dry_weeks, humid_mean, dry_mean, delta}` → `HealthCorrelation {humidWeeksScore←humid_mean, dryWeeksScore←dry_mean}`; `null` until 2 + 2 weeks of history — keep the empty state. |
| `loadHomeInsight()` | now backed by `GET /v1/home`: the newest `changes[]` entry composes the `HomeEnvironmentInsight`-style headline (`title←detail`, `tone` from `kind` — `new_growth`/`flowering`/`improved` read positive, `worse` reads heads-up); with no changes yet, fall back to `climate.label`. Keep the mock text only when both are empty. |
| Home screen (new) | `GET /v1/home` feeds the rest of the screen too: `climate` → the environment status card (`kind`, `label`, `mean_temp_c`, `mean_humidity_pct`, `rain_mm_30d`, `days`), `null` until the account has a home cell. `suggestions[]` → a new "plants you might like" row (`species`, `reason`). `blooming_nearby[]` → a new "blooming near you" row, one tile per species with its `photo_url` and `photo_attribution`, tapping through to the species page when `species_id` is set. Cached per user for an hour server-side; any plant or photo write (check-in, create, edit, delete, species correction, located upload) refreshes it server-side, so re-fetch after such an action rather than trusting the local copy. |
| `loadWeather()`, `loadEnvironmentHistory()` | **No backend endpoint yet** (§7). Keep the mock `WeatherData`/`EnvPoint` for these two calls; the backend uses weather internally (care plans, insights). |

Always render `meta.attribution` on this screen — `GET /v1/home`'s `meta.attribution` carries both the Open-Meteo and iNaturalist lines, since the blooming-near-you row is now part of it.

### 3.8 `NotificationsRepository`

**No backend yet, and no push either** (§7): `PUT /v1/me/devices` stores the token and nothing is
ever sent, so any reminder the app promises has to be a local notification it schedules. Keep the
mock — everything the feed would list is derivable from `care_history` (`added`, `watered`,
`watering_skipped`, `note`, `condition_update`, `check_in_missed`, `species_corrected`, `resumed`,
and `treatment_opened|resolved|extended|escalated|superseded|review_deferred|abandoned|problem_added`),
`needs_attention`, and new insights (`isNew`).

---

## 4. What the backend changes about the app's behaviour (read before wiring)

1. **`health_score` is what the photograph showed, and nothing else moves it.** The mock deltas
   (+3/−2/−8, +2/+1) are gone and so is everything that used to nudge the number. A clean
   check-in anchors at **90**; 100 is only a clean photo that also improved and put out new
   growth; findings subtract from 90, and the reviewer's verdict band bounds the result.
   **Logging a watering does not change the score** — a watering is care *given*, which is
   `care_score` — and neither do the owner's verdict, adherence or the weather. A new score is
   `previous + alpha × (this photo − previous)`, so one bad photo moves a plant only part of the
   way; `provisional: true` marks one the reviewer could barely read. `health_score` is `null`
   only when nothing has ever scored the plant.
2. **Bands:** `thriving ≥ 70 · watch 40–69 · critical < 40`. **There is no `"paused"` band any
   more** — a paused plant reads `{"care_status": "paused", "health_score": 72, "health_band":
   null}`: the number is kept as the last thing anybody knew, the band goes away. Render no band
   whenever `health_band` is null, and branch on `care_status` for the paused state.
3. **`breakdown` is for taking a score apart, not a display shape.** `HealthPoint.breakdown` is
   every number the day's score was made of (`breakdown.version`, currently 1: `condition`,
   `trend`, `new_growth`, `raw`, `alpha {value, reason}`, `photo_quality`, `previous_health`,
   `health`). `null` on a carry-forward day, and the shape may change — read it for a "why this
   number" sheet, never as a fixed model. Same for `risk.breakdown`.
4. **`risk` is on two responses only.** `GET /v1/plants/{id}` and the `plant` inside a finished
   check-in compute it; it is `null` everywhere else a plant is returned (the list, the history,
   and every write that hands a plant back — create, patch, species correction, water,
   water/skip, notes, resume, schedule edit). **Branch on `risk?.level`, not on the object's
   presence** — a null `risk` on a watering's response means "not computed here", so do not clear
   a risk banner off it; refetch the detail. `level` is `low | medium | high`; `reasons` are short
   phrases to print verbatim ("heatwave Tue–Thu"), empty exactly when `level` is `"low"`.
5. **`care_score` (0–100) is the owner's side**, not the plant's: how much of the care that was
   due over the last 30 days was given on time (waterings and steps weighted 2, check-ins 1).
   It is **100 when nothing was due**, and `null` on a day no sweep reached — read the plant's
   `care_score`, not the last history point's. A second dial beside health, not a replacement.
6. **Check-ins need a photo.** The app's `ConditionUpdate` has no photo field; the backend's does.
7. **`stale` sits between active and paused.** One missed check-in window makes a plant `stale`:
   its score and band stand, its waterings are due, its treatments run, its tasks appear — all
   that is true is that nothing current is known about it. Show it as active with a "we haven't
   seen this one lately" hint and a check-in prompt; do **not** offer resume (`409
   plant_not_paused`, deliberately — it comes back by being checked in on). A *second* missed
   window pauses it, so order the states `active → stale → paused` wherever the app badges them.
8. **Pausing is automatic.** A plant is paused only by the nightly job when a second check-in
   window closes without a check-in; there is no pause endpoint. Pausing also removes the
   plant's outstanding `environment` tasks. `resume` keeps the health history and the score the
   plant already had — the returning check-in is believed outright instead.
9. **Care plans exist, and an item is a stable thing.** `GET /v1/plants/{id}/care-plan` returns
   `items[]` (`watering | treatment | environment | check_in | observe`, each with `title`,
   `detail`, `cause`, `due_at`, `status`, `source_finding_id`, `replaces_item_id`), `rationale`,
   `trigger` and `latest_insight`. A revision is a diff: an item keeps its `id` and `pending`
   status across revisions unless something replaces it, so hold items by `id` rather than
   replacing the list wholesale. `rationale` ends with `" (kept N, superseded M)"` — a ready-made
   "what changed" line. The "Frequency adjusts with weather" copy is now real.
10. **Catalogue is a UUID-keyed, paged, growing list**, not 20 slugs. `glyph`/`ground` (artwork) are
   frontend-only: pick by `latin_name` genus with a default.
11. **Identification returns a real species**, possibly one the catalogue never had (drafted on the
   spot, `review_status: draft`), plus alternatives, typed `findings[]` and the search-to-correct
   path. A finding with a real severity opens a treatment on the spot.
12. **Profile stats are computed** (`Me.stats`); `streakSince` has no backend field yet.
   `stats.average_health` counts only plants under care — `active` **and** `stale`, never
   `paused` — and is `0`, not null, when none of them has been scored.

---

## 5. Model field mapping (`fromJson`)

| App model · field | Backend field | Note |
|---|---|---|
| `Plant.id/nickname/room/indoor` | `id/nickname/room/indoor` | |
| `Plant.species` | `species` (full `Species`) | |
| `Plant.addedOn` | `added_on` | ISO UTC |
| `Plant.healthScore` | `health_score` | nullable — `null` means nothing has ever scored it, **not** paused (§4.1–4.2) |
| `Plant.careStatus` | `care_status` | `active \| stale \| paused` — `stale` is new (§4.7) |
| `Plant.schedule.*` | `schedule.next_watering / next_water_amount_ml / frequency_days / last_watered / last_amount_ml / check_in_interval_days / check_in_window_days / check_in_window_opens / watering_reminder / check_in_reminder / reminder_time` | 1:1, snake_case |
| `Plant.history[]` | `history[] {date, score, breakdown, provisional, care_score}` | 90 days; `score`, `breakdown`, `provisional` and `care_score` are all nullable on a day nothing scored |
| `Plant.updates[]` | not embedded — fetch via the check-in job or care-events | |
| `Plant.careHistory[]` | `care_history[] {id, type, title, detail, at}` | `type` is snake_case (`condition_update`) |
| `Plant.photoCount/streakWeeks/lightStatus/lightDetail/leafDropReported` | `photo_count/streak_weeks/light_status/light_detail/leaf_drop_reported` | |
| — | `health_band` (nullable; no `"paused"` value any more), `care_score`, `risk {level, reasons, breakdown}`, `needs_attention`, `visibility`, `kind` | use `needs_attention` instead of recomputing; `risk` is non-null only on detail and check-in (§4.4) |
| `PlantSpecies.id/number/commonName/latinName/summary/difficulty/light/water/temperature/humidity/nativeRange/matureHeight/growthHabit/tagline/careTips` | `id/number/common_name/latin_name/summary/difficulty/light/water/temperature/humidity/native_range/mature_height/growth_habit/tagline/care_tips` | |
| `PlantSpecies.tags[] / traits / commonIssues[]` | `tags[] / traits[] (indoor,low_light,beginner,pet_friendly) / common_issues[]` | |
| `PlantSpecies.glyph/ground` | — | frontend artwork; default |
| — | `common_names[]`, `toxicity`, `image_url`, `default_care {watering_interval_days, water_amount_ml, check_in_interval_days}`, `review_status` | new |
| `CareTask.id/plantId/title/detail/kind/overdue/done/doneAt` | `id/plant_id/title/detail/kind/overdue/done/done_at`; `kind` is `watering \| condition \| treatment_step \| environment` | `id` is the task's `client_id` (`task-water-…`, `task-cond-…`, `task-tstep-…`, `task-env-…`); keep an `unknown` fallback for a new `kind` |
| `CareTask.courseId/problemId/problem` (new) | `course_id/problem_id/problem` | only on a `treatment_step`, `null` on the other three kinds. `problem_id: "all"` with `problem: "All problems"` is a step for the whole plan |
| `UserProfile.name/email/city/reminderTime/units` | `Me.name/email/city/reminder_time/units` | plus `timezone` (IANA, `"UTC"` until the app sets one) and `consent_training` |
| `UserProfile.plantsKept/underActiveCare/averageHealth/careStreakWeeks` | `Me.stats.plants_kept/under_active_care/average_health/care_streak_weeks` | |
| `IdentificationResult.species/confidence/rationale/alternatives[]` | `AnalysisJob.species/confidence/rationale/alternatives[] {species, scientific_name, confidence}` | `alternatives[].species` may be null → show `scientific_name` |
| `ConditionUpdate.id/plantId/takenAt/verdict/observations/note/scoreDelta` | `checkin.update.id/plant_id/created_at/user_verdict/observations/note` + `checkin.score_delta` (nullable) | plus `photo_id`, `model_verdict`, `verdict_disagreement`, `change_vs_last`, `new_growth`, `flowering`, `photo_quality`, `quality_issue`, `score_before`/`score_after` (both nullable), `alpha`, `provisional` |
| check-in result (new model) | `checkin {plant, update, score_delta, next_check_in, plan_revision_id}` | `plant` is a full `Plant` **with** `risk`; `next_check_in` is a date |
| `Course` (new model) | `id, plant_id, status, severity, started_at, review_at, closed_at, problems[], steps[]` | `status` is `open \| closed`; `review_at` is a date; `severity` is the worst problem's |
| `CourseStep` (new model) | a `TreatmentStep` plus `problem_id` | a taxonomy id, or `"all"` — the same vocabulary `CareTask.problemId` uses, so one widget can render both |
| `CourseProblem` (new model) | `treatment_id, problem_id, problem, severity, tier, status, added_at, finding_id, review_at, closed_at, abandon_reason, superseded_by_id` | worst first; `treatment_id` cross-references `/treatments` |
| `Treatment` (new model) | `id, plant_id, course_id, severity, problem_id, problem, finding_id, tier, status, started_at, review_at, expected_days_to_improve, recurrence, closed_at, abandon_reason, superseded_by_id, steps[]` | `problem` is the display name, ready to show; `review_at` is a date; `course_id` is the plan it is one problem of |
| `TreatmentStep` (new model) | `id, treatment_id, key, position, title, detail, due_at, cadence_days, status, done_at, skip_reason, serves` | `due_at` is a date; `status` is `pending \| done \| skipped \| superseded`; `serves` is `"all"` or `null` |
| note request (new) | `POST …/notes {chips: string[], text?: string}` | 1–7 chips, no repeats; `text` ≤ 200 |
| watering-skip request (new) | `POST …/water/skip {reason}` | `soil_wet \| away \| forgot` |
| task-skip request (new) | `POST /v1/care/tasks/{client_id}/skip {reason?}` | `reason` ≤ 200, optional |
| treatment-abandon request (new) | `POST /v1/treatments/{id}/abandon {reason, note?}` | `too_hard \| plant_recovered \| other`; `note` ≤ 200 |
| course-abandon request (new) | `POST /v1/courses/{id}/abandon {reason, note?}` | the same body; stops every open problem on the plan |
| `AnalysisJob.findings[]` (new) | `findings[] {type, name, problem_id, severity, confidence}` | `type` is `disease \| pest \| abiotic \| nutrient \| none`; `problem_id` is a stable taxonomy id (`pest.spider_mite`) and may be null on old rows |
| `EnvironmentalInsight.id/title/body/kind/isNew` | `DailyInsight.id/headline/body/kind/(day == today)` | kind names differ (see §3.7) |
| `HealthCorrelation.humidWeeksScore/dryWeeksScore` | `correlation.humid_mean/dry_mean` | `headline/body` composed client-side |
| `HomeEnvironmentInsight.title/body/tone` | `home.changes[0].detail` (`title`), tone derived from `kind` | fallback `home.climate.label` when `changes` is empty |
| environment status card | `home.climate.{kind,label,mean_temp_c,mean_humidity_pct,rain_mm_30d,days}` | `null` without a home cell |
| "plants you might like" row | `home.suggestions[] {species, reason}` | `species` is the full `Species` shape |
| "blooming near you" row | `home.blooming_nearby[] {scientific_name, common_name, observations, photo_url, photo_attribution, species_id}` | `species_id` null for species we don't carry; still shown |

Nothing maps `health_v2`, `breakdown_v2` or `update.health_v2_*`, and there is no `include_v2`
query parameter: what those names carried **is** `health_score`, `HealthPoint.breakdown` and
`update.score_before/score_after/alpha/provisional`, on every response that has one to give.

---

## 6. `ApiClient` sketch (Dart, `dio`)

```dart
class ApiClient {
  ApiClient(this._dio, this._tokens, this._interceptors);
  final Dio _dio; final TokenStore _tokens; final List<ApiInterceptor> _interceptors;

  Future<T> send<T>(String path, T Function(dynamic json) parse,
      {String method = 'GET', Object? body, Map<String, Object?> query = const {}, bool auth = true}) async {
    final request = ApiRequest(path, params: query);
    for (final i in _interceptors) await i.onRequest(request);
    try {
      final res = await _call(method, path, body, query, auth);          // adds Bearer, retries once on 401 token_expired after /v1/auth/refresh
      for (final i in _interceptors) await i.onResponse(request, res.data);
      return parse(res.data);
    } on DioException catch (e) {
      final err = (e.response?.data is Map) ? e.response!.data['error'] as Map? : null;
      final ex = ApiException(err?['message'] ?? 'Something went wrong', code: err?['code']);
      for (final i in _interceptors) await i.onError(request, ex);
      throw ex;
    }
  }
}
```

Multipart uploads use `FormData` with `MultipartFile.fromFile(path, filename: 'photo.jpg')` and
the form fields listed in §3.2; polling is a small `Stream.periodic`/loop with a 3-minute ceiling
that stops on a terminal `state`.

---

## 7. Feature availability

| Feature | Backend | App today |
|---|---|---|
| Email sign-up/OTP/sign-in/refresh/reset, Google/Apple id-token | ✅ | mock |
| Profile + computed stats, device token storage | ✅ | hard-coded |
| Species catalogue (paged, filters, featured, detail) | ✅ | 20 seeds |
| Species search by scientific/common name (typeahead) + resolve + correct | ✅ | — |
| Photo upload, identification with confidence/alternatives/initial health | ✅ | scripted |
| Plants CRUD, water, resume, schedule edit, history, care events, photos | ✅ | partial |
| Today's tasks + complete (4 kinds: watering, condition, treatment_step, environment) | ✅ | mock, 2 kinds |
| Skip a treatment step (`/skip`), skip a watering (`/water/skip`) | ✅ | — |
| Quick notes with chips (no camera) | ✅ | — |
| Treatments: list per plant, auto-opened, judged at check-in, abandon | ✅ | — |
| Photo check-in with owner verdict → health score, disagreement flag | ✅ | no photo |
| Care plan per plant (items, rationale, triggers), auto-revision on check-in/overdue/weather/resume/correction | ✅ | — |
| Daily insights (heat / low humidity / rain / low-light season) + humidity correlation | ✅ | mock |
| `stale` after one missed window, pause after a second, daily health points | ✅ (nightly jobs) | mock |
| `care_score` (30-day adherence) and `risk` (the week ahead, detail + check-in only) | ✅ | — |
| Home feed (climate, suggestions, changes, blooming nearby) | ✅ | mock |
| Weather card (`WeatherData`), environment history (`EnvPoint`) | ❌ not yet — keep mock | mock |
| Notifications feed / read state | ❌ not yet — keep mock | mock |
| **Reminders and push delivery** | ❌ **not built.** Tasks and `reminder_time` exist; `Device.push_token` is stored by `PUT /v1/me/devices` and **nothing is ever sent**. Any reminder the app promises must be a local notification it schedules itself. | mock |
| Community / public plants | ❌ M4 | — |
| User time zones (`PATCH /v1/me {timezone}`; every date is the owner's day) | ✅ | — |
| `GET /v1/admin/metrics/problems` | operator-only (403 `admin_only`) — **not for this app**; do not wire it | — |

---

## 8. Suggested order of work

1. `ApiClient` + secure token store + error mapping; `AuthRepository` real; session restore via `GET /v1/me`; **`PATCH /v1/me {timezone}` with the device zone as soon as there is a token** — every date in every later step is wrong without it. Run against `localhost:8010` (OTP codes print in `docker compose logs api`).
2. `PokedexRepository` real (async catalogue) and `Species.fromJson` — unblocks every screen that shows a species.
3. `PlantRepository` real: plants, today (all four task kinds), water, water/skip, resume, schedule; `Plant.fromJson` with `care_status`, the nullable `health_band`, `care_score` and `risk`.
4. Scanning: camera/gallery + location permission → upload → poll → result card with alternatives → species search → `POST /v1/plants {species_id, photo_id}`.
5. Check-in with photo (§3.4) and the result sheet (both verdicts, score before/after — both nullable — `provisional`, next check-in).
6. Treatments screen from `GET /v1/plants/{id}/treatments` (refetched after every check-in), step skip and abandon; quick notes from the plant detail (`POST …/notes`). These are the two new screens the cutover added.
7. Care-plan screen from `GET /v1/plants/{id}/care-plan`; correction flow on the plant detail (§3.6).
8. Insights from `GET /v1/insights` with attribution; keep weather/notifications mocks until their endpoints exist.
9. Home screen from `GET /v1/home` (§3.7, §5): environment status card, "plants you might like" and "blooming near you" rows, and `loadHomeInsight()`'s headline — all one call, cached an hour, refreshed by any plant or photo write.

Postman folders 1 → 8c in `docs/postman/plantsec-m1.postman_collection.json` walk this exact
order against the local stack.
