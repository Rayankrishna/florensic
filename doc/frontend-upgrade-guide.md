# What changed since you integrated (delta guide for the Flutter app)

_For `Rayankrishna/florensic`, written 2026-10-05. This is a **delta**, not a third guide.
Anything it does not mention has not changed: read
[`docs/frontend-api-guide.md`](frontend-api-guide.md) for every endpoint, shape and error, and
[`docs/frontend-integration-guide.md`](frontend-integration-guide.md) for how each one maps onto
the app. [`docs/openapi.json`](openapi.json) is the tie-breaker._

## 1. Read this first

You integrated against the two guides as they stood on `main` on 2026-09-25; everything in them
up to that date still holds except what is listed below. Migration 0020 rebuilt the health score:
`health_score` is the same field in the same place on the same responses and it now means
**what the photograph showed, blended into what we already believed**, so a number your app
stored before this will not line up with one it fetches after. Every field named here is already
live on the test server, and the server has not moved (same ngrok setup, see
[`docs/ngrok-testing.md`](ngrok-testing.md)).

## 2. Breaking changes, update these or the app misreads data

| Where | Before | Now | What to change in the app |
|---|---|---|---|
| `health_score`, clean check-in | about 70, drifting with adherence | **90**. 100 only for a clean photo that also improved and put out new growth | Drop any hard-coded "healthy is 70" copy or threshold. A plant that used to sit near 70 now sits near 90 |
| `health_score`, plant kept without a photo | `80` | `null` (nothing has scored it) | Render "not scored yet", not a 0 or an 80 |
| `health_score`, plant kept from a photo | `80` | the identification's own reading: 90 less what its findings cost | Nothing to change beyond trusting the number |
| `health_score`, how it moves | each event nudged it | `previous + alpha x (this photo - previous)`. Only a check-in photo moves it | Remove any local delta arithmetic |
| `POST /v1/plants/{id}/water` | score `+1`, capped by the last photo verdict | the score **does not move** | Stop showing a score bump after watering. The response is still the full `Plant` |
| owner verdict, treatment effect, adherence, weather | each moved the score (±3, ±8, ±3, ±3) | none of them move it. `user_verdict` and `verdict_disagreement` are recorded only | Remove copy that promises the score reacts to these |
| `health_score: null` | meant "paused" | means **"never scored"** | Never infer paused from a null score. Branch on `care_status` |
| `health_band` | always a string, one of `thriving/watch/critical/paused` | **nullable**, and the `"paused"` value is gone. A paused plant reads `{"care_status": "paused", "health_score": 72, "health_band": null}` | Make the field nullable. Render no band when it is null. Bands are still `thriving >= 70 · watch >= 40 · critical` |
| `care_status` | `active \| paused` | `active \| stale \| paused` | Widen the enum with an unknown fallback. Order the states `active -> stale -> paused` |
| `stale` behaviour | did not exist (one missed window paused the plant) | one missed check-in window sets `stale`: score and band stand, waterings are due, treatments run, tasks appear. A **second** missed window pauses | Show `stale` as active plus a "we have not seen this one lately" hint and a check-in prompt |
| `POST /v1/plants/{id}/resume` | set the score to 70; offered on anything not active | keeps the score the plant already had; **a stale plant cannot be resumed** (`409 plant_not_paused`) | Offer resume only when `care_status == "paused"`. For `stale`, offer a check-in |
| pausing | only froze the plant | also **removes the plant's outstanding `environment` tasks** dated today or later (completed ones stay) | Refetch `GET /v1/care/today` after a pause is noticed |
| `?include_v2`, `health_v2`, `breakdown_v2`, `update.health_v2_*` | shadow fields behind a query flag, never in `openapi.json` | all gone. Sending `include_v2=true` is not an error, it is an unknown query parameter and is ignored | If you coded against the shadow fields, rename: they are now `health_score`, `HealthPoint.breakdown`, and `update.score_before/score_after/alpha/provisional`, unasked for on every response |
| `CareTask.kind` | `watering \| condition` | `watering \| condition \| treatment_step \| environment` | Widen the enum **and tolerate a value you do not know** (render `title`/`detail`, allow complete). Client-id prefixes: `task-water-<plantId>`, `task-cond-<plantId>`, `task-tstep-<stepId>`, `task-env-<plantId>-<YYYYMMDD>` |
| `PlantOut` | no `care_score`, no `risk` | gains `care_score: int\|null` and `risk: Risk\|null` | Add both to the model. `risk` is computed only on `GET /v1/plants/{id}` and on the `plant` inside a finished check-in; it is `null` on the list, the history and every write that hands a plant back. **Branch on `risk?.level`, never on the object's presence**, and do not clear a risk banner off a watering's response |
| `HealthPointOut` | `{date, score}` | gains `breakdown: object\|null`, `provisional: bool\|null`, `care_score: int\|null` | Add them as nullable. Only `date` and `score` are required in the schema, so tolerate the three being absent as well as null |
| `stats.average_health` | averaged whatever had a score | averages only plants **under care**: `active` and `stale`, never `paused`. It is `0`, not null, when none of them has been scored | Do not show "0 % health" for a new or all-paused account. `stats.under_active_care` counts `active` and `stale` too |
| check-in `update.score_before` / `score_after` | a number on every check-in | both nullable. `score_before` is null on a plant's **first scored check-in** (nothing to blend into); both are null on a check-in the new scorer never scored | Make both nullable |
| `checkin.score_delta` | a number on every check-in | nullable, for the same reason | Render the delta chip only when `score_delta != null` |
| check-in `update` | no `alpha`, no `provisional` | gains `alpha: float\|null` (0 to 1, how much this photo was believed) and `provisional: bool\|null` (the photo was too poor to read) | Add both. On `provisional: true` show "we could not see much, try another photo"; the next usable photo is believed outright |
| check-in `update` | `photo_quality` / `quality_issue` absent | both present and **required** (nullable values) | Add them; they say why a check-in was provisional |
| care plan `meta.timezone` | `"UTC"` on every document | the **owner's** zone, on the home feed, the insights feed and the care plan alike | Read `meta.timezone` per document rather than assuming UTC |
| care plan revisions | every pending item was superseded on each revision | a revision is a **diff**: an item keeps its `id` and `pending` status unless something replaces it or the plan exceeds six open items | Hold plan items by `id` instead of replacing the list wholesale. `rationale` now ends with `" (kept N, superseded M)"` |
| `AnalysisJob` (identify) | `species`, `confidence`, `rationale`, `alternatives[]`, `initial_health` | also `findings[] {type, name, problem_id, severity, confidence}` | Optional to show, but a finding with a real severity opens a treatment on the spot |
| `Me` / `UserOut` | no `timezone` | `timezone` present and **required** (IANA name, `"UTC"` until the app sets one) | Add the field, then see §3.1 |
| `CareEvent.type` | `added`, `watered`, `condition_update`, `check_in_missed`, `species_corrected`, `resumed` | adds `watering_skipped`, `note`, `treatment_opened`, `treatment_resolved`, `treatment_extended`, `treatment_escalated`, `treatment_superseded`, `treatment_review_deferred`, `treatment_abandoned`, `treatment_step_done`, `treatment_step_skipped`, `treatment_problem_added` | Give the timeline a default icon and label for an unknown type |

**Today's list says which plan a step belongs to.** A `treatment_step` task on
`GET /v1/care/today` gains `course_id`, `problem_id` and `problem`. `problem_id: "all"` (with
`problem: "All problems"`) marks a step that serves every problem on the plan. All three are
`null` on a watering, a check-in and an environment task. One plant's steps already arrive
grouped by plan, shared steps first — a client that wants headings need only break on
`course_id`.

**A step is no longer charged against `care_score` on the day it was created.** A plant added
this morning from a photograph that found three problems used to read `care_score: 0` before the
owner had done anything; the care window now ends before today, so today's steps are on the list
and are not yet care withheld.

**No property was renamed or removed** from `openapi.json` in this release. The only two type
changes are `CareTaskOut.kind` (wider enum) and `PlantOut.health_band` (now nullable); everything
else listed above is an addition or a change of meaning.

## 3. New endpoints, optional to adopt, in the order worth doing

### 3.1 `PATCH /v1/me {timezone}` (do this one first)

Every date in every other call depends on it.

- **Request:** `{"timezone": "Asia/Kolkata"}`, an IANA name. The field joins the existing
  `{name?, city?, units?, reminder_time?, consent_training?}` body.
- **Response:** `200 Me`, which now carries `timezone`.
- **Errors:** `422 invalid_timezone` when the tz database has no such zone.
- **Screen:** none of its own. Send the device zone (`flutter_timezone`) right after the first
  successful token exchange, and again whenever it differs from `Me.timezone`. Settings can
  expose it later.

### 3.2 `POST /v1/plants/{plant_id}/notes`

The no-camera answer: what the owner can tell us without a photo.

- **Request:** `{"chips": ["drooping", "dry_soil"], "text": "hot week"}`. One to seven chips from
  `drooping · dry_soil · wet_soil · yellowing · leaf_drop · pests_seen · new_growth`, no repeats.
  `text` is optional, at most 200 characters, and is never parsed.
- **Response:** `200 Plant` (full plant, so `replacePlant`).
- **Errors:** `409 plant_not_active` when the plant is paused (a **stale** plant takes notes
  normally); `422` for an unknown or repeated chip, or an empty list.
- **Effect:** it does **not** move `health_score`. It pulls `schedule.check_in_window_opens`
  forward by up to two days, sets `leaf_drop_reported` for `leaf_drop`, writes a `note` care
  event, and is shown to the next check-in reviewer.
- **Screen:** plant detail, a sheet of chips beside the check-in button.

### 3.3 `POST /v1/plants/{plant_id}/water/skip`

- **Request:** `{"reason": "soil_wet"}`, one of `soil_wet | away | forgot`.
- **Response:** `200 Plant`.
- **Errors:** `409 plant_not_active` on a paused plant.
- **Effect:** `soil_wet` counts as care **given** and pushes `next_watering` two days out, so the
  task leaves today's list. `away` and `forgot` change nothing: the watering is still due and the
  task stays. Nothing here moves `health_score`, and `last_watered` is untouched.
- **Screen:** today's list, a secondary action on a watering task.

### 3.4 `POST /v1/care/tasks/{client_id}/skip`

- **Request:** `{"reason": "away for the week"}`, optional, at most 200 characters.
- **Response:** `200 CareTask` with `done: true`.
- **Errors:** `400 task_not_skippable` for any kind other than `treatment_step`;
  `404 task_not_found` for a client id that is not on this owner's list today.
- **Effect:** the step becomes `skipped` rather than `done`, it does **not** come back on its
  cadence, and it still counts against `care_score` as care that was due.
- **Screen:** today's list, swipe or long-press on a `treatment_step` task only.

### 3.5 `GET /v1/plants/{plant_id}/treatments`

A treatment is one problem the plant has plus the course prescribed for it. Courses open
automatically: from the identification when a plant is kept from a photo, and from any check-in
that finds a problem. At most one open course per problem per plant.

- **Response:** `200 Treatment[]`, newest first, closed ones included, steps in order.
  `Treatment` is `{id, plant_id, problem_id, problem, finding_id, tier, status, started_at,
  review_at, expected_days_to_improve, recurrence, closed_at, abandon_reason, superseded_by_id,
  steps[]}`. `problem` is the display name, ready to show. `status` is
  `active | improving | escalated | resolved | superseded | abandoned`.
  `TreatmentStep` is `{id, treatment_id, key, position, title, detail, due_at, cadence_days,
  status, done_at, skip_reason, serves}` with `status` of `pending | done | skipped |
  superseded`. `Treatment` also carries `course_id` and `severity`, and `serves` on a step is
  `null` or `"all"` — see §3.7, which is the shape to build the screen against.
- **Errors:** `404 plant_not_found`.
- **Effect to expect:** every check-in judges every open course, so refetch after a check-in job
  finishes. `status`, `tier`, `review_at` and `steps` move on their own. `superseded` on a step
  is the **system** dropping it, not the owner failing it. `superseded_by_id` on a treatment
  points at the course that replaced it. Opening a course also shortens
  `schedule.check_in_interval_days` without the owner touching anything.
- **Screen:** a new treatments screen off plant detail. Render it as history.

### 3.6 `POST /v1/treatments/{treatment_id}/abandon`

- **Request:** `{"reason": "too_hard", "note": "optional"}`. `reason` is
  `too_hard | plant_recovered | other`; `note` is at most 200 characters.
- **Response:** `200 Treatment` with `status: "abandoned"`.
- **Errors:** `409 treatment_not_open` (only an open course can be stopped);
  `404 treatment_not_found` (also what somebody else's id returns).
- **Effect:** the reason is not cosmetic. `plant_recovered` closes the course as a resolution:
  the remaining steps stop counting against `care_score`, the finding is marked resolved, and the
  problem returning within ninety days starts the next course at tier 2. `too_hard` records care
  asked for and not given, and stops the same problem opening a new course for a fortnight.
  `other` is neither. Either way the steps leave today's list and the check-in cadence goes back.
- **Screen:** treatments screen, a "stop this" action with a three-way reason picker.

### 3.7 `GET /v1/plants/{plant_id}/courses` — build the screen against this one

**A plant has one treatment plan, not one course per problem.** One photograph can find three
problems, and until this they became three separate `Treatment` rows with eight steps between
them all due the same day. They are now **members of one course**: the same rows, grouped, with
the duplicated steps merged and the day-one pile spread out.

- **Response:** `200 Course[]`, newest first, closed ones included.
  `Course` is `{id, plant_id, status, severity, started_at, review_at, closed_at, problems[],
  steps[]}`. `status` is `open | closed` — it is open while **any** problem on it is. `severity`
  is the worst problem's (`low | medium | high`). `review_at` is the earliest open problem's
  review date.
- `problems[]` is **worst first**:
  `{treatment_id, problem_id, problem, severity, tier, status, added_at, finding_id, review_at,
  closed_at, abandon_reason, superseded_by_id}`. `status` is the same six values a `Treatment`
  has, because that is exactly what each member is. `added_at` is when that problem joined the
  plan — the same instant for everything one scan found, and its own day for a problem a later
  check-in added.
- `steps[]` is the **whole plan in one order**, already sorted: shared steps first, then the
  worst problem's, then the protocol's own order. Each step is a `TreatmentStep` plus
  **`problem_id`** — a taxonomy id, or `"all"` for a step that serves every problem on the plan,
  the same vocabulary `GET /v1/care/today` uses. `treatment_id` says which problem's row it hangs
  from; `serves` is the raw column behind `problem_id`. **`problem_id: "all"`** — "stand it away
  from the others" — is one instruction however many pests prompted it. Show the label; do not
  show the step twice, and do not nest the list under `problems[]`.
- **Errors:** `404 plant_not_found`.
- **Effect to expect:** a problem found at a later check-in **joins** the open plan rather than
  starting a second one, and the owner's only notice of that is a `treatment_problem_added` care
  event. At most six steps fall due on any one day and fifteen on a plan in all.
- **Screen:** replace the treatments screen's top level with courses. `/treatments` has not
  changed and is still the per-problem history — keep it for "has this plant had thrips before?".

### 3.8 `POST /v1/courses/{course_id}/abandon`

- **Request:** `{"reason": "too_hard", "note": "optional"}` — the same body as §3.6.
- **Response:** `200 Course` with `status: "closed"` and every problem `abandoned`.
- **Errors:** `409 course_not_open` (every problem on it has already finished);
  `404 course_not_found` (also what somebody else's id returns).
- **Effect:** §3.6's rules, applied to every open problem at once and in one transaction. The
  per-treatment route stays for an owner who has finished with one problem and not the others.
- **Screen:** a "stop the whole plan" action on the course, beside the per-problem one.

### Two notes

- **The species confirm-or-correct trio is not new.** `GET /v1/species/suggest`,
  `POST /v1/species/resolve` and `POST /v1/plants/{id}/species` were already in §3.6 of the
  integration guide you worked from. Nothing about them changed. Skip.
- **`GET /v1/admin/metrics/problems` is not for this app.** It is operator-only
  (`403 admin_only` without `role: "admin"`). Do not wire it.

## 4. New fields you can show without new calls

- **`breakdown`** on a `HealthPoint` is every number that day's `score` was made of, so a score
  can be explained without re-running anything. It is `null` on a day nothing scored (a
  carry-forward, or anything before the scorer recorded one), and its shape is versioned
  (`breakdown.version`, currently 1). **It is not a display shape.** Use it for a "why this
  number" sheet, never as a fixed model class. Same for `risk.breakdown`.
- **`care_score` (0 to 100)** on the plant is the owner's side, not the plant's: how much of the
  care that was due over the last 30 days was given on time (waterings and steps weighted 2 each,
  check-ins 1). It is **100 when nothing was due**, and `null` on a day no sweep reached. Read
  the plant's `care_score`, not the last history point's. A second dial beside health.
- **`risk {level, reasons, breakdown}`** is about the coming week. `level` is `low | medium |
  high`. **`reasons` are short phrases meant to be printed verbatim** ("heatwave Tue to Thu",
  "no photo in 21 days", "possible underwatering, 2 waterings missed"), and the list is empty
  exactly when `level` is `"low"`. Detail and check-in only, see §2.
- **`provisional`** on a health point and on a check-in means the photograph was too poor to
  read, so the number is held lightly. A carry-forward point on a stale plant is provisional too.
- **Treatment care events** (`treatment_opened`, `treatment_resolved`, `treatment_extended`,
  `treatment_escalated`, `treatment_superseded`, `treatment_review_deferred`,
  `treatment_abandoned`, `treatment_step_done`, `treatment_step_skipped`), plus `note` and
  `watering_skipped`, already arrive in `care_history` and `GET /v1/plants/{id}/care-events`.
  The timeline gets richer with no new call.
- **`health_points[].care_score` and `.provisional`** let the history chart mark the days the
  score was a guess and plot adherence beside health.

## 5. Dates and time zones

- A "day" is now the **owner's** day, in the IANA zone on their profile (default `"UTC"`).
- **Owner-local dates** (`YYYY-MM-DD`, parse as a plain local date, do **not** call
  `DateTime.parse(d).toLocal()`): today's task list, `schedule.next_watering`,
  `schedule.check_in_window_opens`, an insight's `day`, a `HealthPoint.date`, a care-plan item's
  `due_at`, a `TreatmentStep.due_at`, `Treatment.review_at`, `checkin.next_check_in`.
- **UTC instants** (ISO-8601, convert for display as you already do): every `*_at` timestamp,
  including `created_at`, `started_at`, `closed_at`, `done_at`, `CareEvent.at`.
- `meta.timezone` on the home feed, the insights feed and the care plan says which calendar that
  document is on. Read it rather than assuming.
- Upload and analysis quotas still reset on a **UTC** day, which is ours rather than the owner's.
- The one-time call: `PATCH /v1/me {timezone}` on first launch, as soon as there is a token
  (§3.1). Without it the owner stays on UTC and every date above is a day out.

## 6. Error codes added

New since the guides you worked from:

| HTTP | `error.code` | When | App reaction |
|---|---|---|---|
| 400 | `task_not_skippable` | `/skip` on anything but a `treatment_step` | offer skip only on that kind |
| 403 | `admin_only` | `GET /v1/admin/metrics/problems` without an admin account | not reachable from this app |
| 404 | `treatment_not_found` | unknown id, or somebody else's | refetch the treatments list |
| 404 | `course_not_found` | unknown course id, or somebody else's | refetch `GET /v1/plants/{id}/courses` |
| 409 | `course_not_open` | abandoning a plan whose every problem has finished | refetch the courses list |
| 409 | `plant_not_active` | `notes` or `water/skip` on a **paused** plant | hide those actions when paused |
| 409 | `treatment_not_open` | abandoning a closed course | refetch the treatments list |
| 422 | `invalid_timezone` | `PATCH /v1/me {timezone}` with a name the tz database does not have | fall back to `"UTC"` |

`plant_not_paused` is not new, but it has a new case: on a **stale** plant it means "check in
rather than resume", not "this plant is fine". `task_not_skippable` and `admin_only` are
documented in §4 and §7 of the API guide rather than in its §9 table.

## 7. Still not built

- **Reminders and push delivery.** Tasks and `reminder_time` exist, and `PUT /v1/me/devices`
  stores the token, but **nothing is ever sent**. Any reminder the app promises must be a local
  notification it schedules itself.
- **Notifications feed and read state.** Keep the mock; derive it from `care_history`,
  `needs_attention` and new insights.
- **Weather card and environment history** (`WeatherData`, `EnvPoint`). Keep the mock.
- **Community layer** (public plants, feed). M4. `visibility: public` is stored, served nowhere.
- **Pl@ntNet pest/disease second opinion.** Built but off; no API change when it is turned on.
- Owner time zones have **left** this list. They are live (§3.1, §5).

## 8. Checklist

- [ ] Send `PATCH /v1/me {timezone}` with the device zone right after the first token exchange, and whenever it differs from `Me.timezone`.
- [ ] Add `timezone` to `UserProfile` / `Me` (required, IANA string).
- [ ] Make `Plant.healthBand` nullable and delete the `"paused"` band from the enum and from the band switch.
- [ ] Stop reading `health_score == null` as paused; branch on `care_status` everywhere.
- [ ] Widen `care_status` to `active | stale | paused` with an unknown fallback, and order badges `active -> stale -> paused`.
- [ ] Show resume only for `paused`; show a check-in prompt for `stale`.
- [ ] Add `care_score` and `risk {level, reasons, breakdown}` to `Plant`; branch on `risk?.level` and never clear a risk banner from a response that did not compute it.
- [ ] Add `breakdown`, `provisional` and `care_score` to `HealthPoint`, all nullable and all possibly absent.
- [ ] Widen `CareTask.kind` to four values plus an `unknown` fallback that still renders `title`/`detail`.
- [ ] Remove the local score arithmetic: no delta after watering, no adherence or weather nudge.
- [ ] Make `score_before`, `score_after` and `score_delta` nullable in the check-in model; render the delta chip only when it is non-null.
- [ ] Add `alpha`, `provisional`, `photo_quality`, `quality_issue` and `flowering` to the check-in model, and a "we could not see much" hint for `provisional`.
- [ ] Parse every owner-local date as a plain date, and keep `toLocal()` for `*_at` instants only (§5).
- [ ] Hold care-plan items by `id` across revisions instead of replacing the list; show the `" (kept N, superseded M)"` tail as the "what changed" line.
- [ ] Add `Course`, `CourseProblem`, `Treatment` and `TreatmentStep` models; build the treatments screen off `GET /v1/plants/{id}/courses` (one plan per plant) and keep `/treatments` for the per-problem history. Refetch after every check-in.
- [ ] Render a step with `serves: "all"` once, labelled for the whole plan, and never under one problem.
- [ ] Add `course_id`, `problem_id` and `problem` to `CareTask` and group today's steps by `course_id`.
- [ ] Wire step skip (`/care/tasks/{client_id}/skip`) and treatment abandon with its three-way reason picker.
- [ ] Wire the quick-note chip sheet (`/plants/{id}/notes`) and the watering skip (`/plants/{id}/water/skip`) on the plant detail and today's list.
- [ ] Add the new `CareEvent.type` values to the timeline, with a default for unknown ones.
- [ ] Add `task_not_skippable`, `plant_not_active`, `treatment_not_found`, `treatment_not_open`, `course_not_found`, `course_not_open` and `invalid_timezone` to the error mapper.
- [ ] Refetch `GET /v1/care/today` after a plant is seen to be paused, since its environment tasks are gone.
- [ ] Fix the profile screen so `stats.average_health` of `0` reads as "nothing scored yet", not "0 % healthy".
- [ ] Delete any `include_v2` query parameter and any `health_v2` / `breakdown_v2` field from the client.
