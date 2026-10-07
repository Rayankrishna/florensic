# Florensic API — guide for the Flutter team

_As of 2026-09-30 (rev 5) · Florensic API 0.1.0 · every route below is live on the local stack at
`http://localhost:8010` and described exactly in [`docs/openapi.json`](openapi.json)
(Swagger UI at `/docs`). Postman collection and click-through walkthrough:
[`docs/postman/`](postman/) and [`docs/testing-in-postman.md`](testing-in-postman.md)._

This is the human map of the API: the conventions that apply everywhere, then the app's
screens as request sequences, then every endpoint and the shapes they return. Every route in
sections 2–8 is live today; section 10 lists what is **not built yet**, so nothing here is a
promise about a route you cannot call.

---

## 1. Conventions

| Topic | Rule |
|---|---|
| Base path | `/v1/…`. Only `GET /health` sits outside it. |
| Auth | `Authorization: Bearer <access_token>`. Access tokens live **15 min**, refresh tokens **30 days** and rotate on every refresh (a reused refresh token is rejected with `token_reused`). Routes marked *public* need no header. |
| Bodies | JSON, `snake_case`. Ids are UUID strings. Timestamps are ISO-8601 in **UTC**; dates are `YYYY-MM-DD`. |
| Days | A "day" is the **owner's** day, in the zone on their profile (`PATCH /v1/me {timezone}`, default `"UTC"`). Every date the API answers with — a watering's due date, today's task list, a check-in window, an insight's `day` — is a date on that calendar, so set the timezone at sign-in and render dates as plain local dates rather than converting them. Timestamps are still UTC instants: convert those. **`meta.timezone` tells you which calendar each document is on, and all three now report the owner's zone** — the home feed's, the insights feed's and the care plan's, the last of which said `"UTC"` until plan items and treatment steps were dated on the owner's day too. Read it rather than assuming. The daily upload and analysis quotas also reset on a UTC day, which is ours rather than the owner's. |
| Errors | One envelope for every failure, including validation: `{"error": {"code": "plant_not_paused", "message": "This plant is already under active care."}}`. Switch on `code` (stable); `message` is safe to show. 422 adds `details` from validation. Full list in §9. |
| Rate limits | Auth routes 10/min per IP; public reads (species, suggest) 60/min per IP; OTP 5/hour per email. Over the limit → 429 `rate_limited`. **Debounce the species typeahead (~300 ms).** |
| Async jobs | Photo analysis is a job. Upload → `202 {job_id}` → poll `GET /v1/analysis/{job_id}` every ~2 s until `state` is `done`, `no_confident_match` or `failed`. Identification takes ~10–60 s; a check-in ~10–40 s. `retryable: true` on a failure means "try the same request again later". |
| Full plant on write | Every plant mutation (create, patch, water, resume, schedule) returns the **full `Plant`**, so you can replace local state from the response instead of refetching. |
| Location | Send `lat`/`lon` with photo uploads when the user allows it. Coordinates are stored server-side only and **never** appear in any response; weather, home area and insights depend on them. |
| Weather attribution | Wherever the app shows insights or the care plan's weather reasoning, display `meta.attribution` — always `"Weather data by Open-Meteo.com (CC BY 4.0)"`. |

---

## 2. Flow 1 — Sign up, verify, sign in, refresh

```
POST /v1/auth/sign-up {name, email, password}      → 202  (OTP emailed; no tokens yet)
POST /v1/auth/otp/verify {email, code}              → 200 TokenPair
   … app uses access_token; when it expires:
POST /v1/auth/refresh {refresh_token}               → 200 TokenPair   (old refresh token is now dead)
POST /v1/auth/sign-in {email, password}             → 200 TokenPair   (returning user)
POST /v1/auth/sign-out {refresh_token?}             → 204            (auth; revokes refresh token(s))
```

- `TokenPair = {access_token, refresh_token, token_type: "bearer", expires_in: 900, user: User}`.
- Unverified email → `403 email_unverified` on sign-in; call `POST /v1/auth/otp/request {email, purpose: "signin"}` then verify.
- Wrong code → `400 otp_invalid`; six-digit codes expire after **10 min** (`otp_expired`); five wrong tries lock the code (`otp_locked`).
- Password reset: `otp/request {purpose: "reset"}` → `POST /v1/auth/password/reset {email, code, new_password}` → 204.
- Social: `POST /v1/auth/oauth/google|apple {id_token, name?}` → 200 TokenPair. Fixture tokens work in dev only.
- Profile: `GET /v1/me` → `Me` (profile + `stats {plants_kept, under_active_care, average_health, care_streak_weeks}`); `PATCH /v1/me {name?, city?, units?, reminder_time?, timezone?, consent_training?}` (`timezone` is an IANA name such as `Asia/Kolkata`; an unknown one is `422 invalid_timezone`); `PUT /v1/me/devices {platform: android|ios, push_token}` → 204; `DELETE /v1/me` → 204 (soft delete; the account is gone for the app).

---

## 3. Flow 2 — Identify a plant from a photo and add it

```
POST /v1/photos  (multipart)                        → 202 {job_id, photo_id}
   file, purpose=identify, framing=leaf|whole_plant|flower, source=camera|gallery,
   lat?, lon?, location_accuracy_m?, captured_at?
GET  /v1/analysis/{job_id}   (poll ~2 s)            → 200 AnalysisJob
   state: queued → running → done | no_confident_match | failed
POST /v1/plants {species_id, photo_id, nickname?, room?, indoor?}   → 201 Plant
GET  /v1/plants/{plant_id}/care-plan                → 200 CarePlan   (first plan is written on creation)
```

**Reading the result.** When `state == "done"`: `species` (full `Species`, use its `id` for the
create call), `confidence` 0–100, `rationale`, `alternatives[]` (`{species|null, scientific_name,
confidence}` — show these as "not this? maybe…" chips), and `initial_health {verdict, observations[],
severity}`. Since `identify.v2` the same response also carries `findings[]`
(`{type, name, problem_id, severity, confidence}`) — the typed problems the scan actually saw,
where `problem_id` is a stable taxonomy id (`pest.spider_mite`, `abiotic.low_humidity`, …) you
can group, count and compare across check-ins, unlike the free-text `name`; it is `null` only on
rows written before the taxonomy existed. `no_confident_match` means confidence was under 40 or
the species could not be resolved — show the alternatives and the search field instead of a result card.

**If the user says the result is wrong — the correction search field.**

```
GET /v1/species/suggest?q=<typed text>&limit=8     (public; debounce ~300 ms; 2+ chars)
→ 200 {query, items: [{source, species_id, external_id, scientific_name, common_name, matched_term}]}
```

- Works with scientific *and* common names: "monst", "swiss cheese", "tulsi", "money plant".
- Every row is a species — a genus (`Monstera`) is never suggested. Show `scientific_name` with `common_name`; `matched_term` is the text that matched (e.g. "Tulsi"), useful to highlight.
- Whichever row the user taps, send it back as it came and take the `species_id` from the answer:

```
POST /v1/species/resolve {source, species_id?, external_id?, scientific_name, matched_term?}   (auth)
→ 200 {species_id, scientific_name, created: false}   we already had the plant
→ 201 {species_id, scientific_name, created: true}    we drafted it for the catalogue
```

  Then `POST /v1/plants {species_id, photo_id?, …}` for a new plant, or `POST /v1/plants/{plant_id}/species {species_id}` to correct one you already have. A `catalogue` row resolves instantly; an `inaturalist` row we have never seen takes **~10 s** (one model call writes its care card), so show a spinner and allow 30 s. `503 species_draft_unavailable` means the model, GBIF or the day's budget refused — offer a retry; `429 species_draft_quota_exceeded` means this user has added their day's worth of new species (5), which only ever happens on the drafting path — plants we already carry still resolve. `scientific_name` must look like one (letters, spaces, `-`, `.`, `'`, `×`) and `matched_term` is capped at 120 characters; send the suggestion back unchanged and neither can bite. Resolving the same plant twice, under any of its names, always returns the same `species_id` with `created: false`.
- Under 3 characters only the catalogue is searched; a provider outage still returns catalogue hits. The typeahead learns: the name a user types to reach a plant becomes one of that species' common names, so the next person matches our catalogue directly.

**Photos of a plant.** `GET /v1/plants/{plant_id}/photos` → `Photo[]`; `GET /v1/photos/{photo_id}` → `Photo` with `urls {original, working, thumb}` — signed URLs valid **15 min**, refetch rather than cache them.

Uploads: JPEG/PNG/HEIC, ≤ 12 MB, short side ≥ 480 px; `413 payload_too_large` otherwise. Daily caps per user: uploads and analyses (`upload_quota_exceeded`, `analysis_quota_exceeded`, both 429).

**What a sick scan sets in motion.** If the identification's `findings[]` carry a severity, `POST /v1/plants` does more than keep the plant: its `health_score` anchors below the clean 90, a care plan is written, and **one treatment plan opens** covering every problem found — read it at `GET /v1/plants/{plant_id}/courses` right after the add, and its first steps are already on `GET /v1/care/today` as `treatment_step` tasks (Flow 3). `POST /v1/plants` can take a little while on a sick scan because the plan is drafted inside the request; show a spinner, do not retry.

---

## 4. Flow 3 — Daily care

```
GET  /v1/care/today                                 → 200 CareTask[]   {id, plant_id, kind: watering|condition|treatment_step|environment, title, detail, overdue, done, done_at, course_id?, problem_id?, problem?}
POST /v1/care/tasks/{client_id}/complete            → 200 CareTask     (completing a watering task waters the plant)
POST /v1/care/tasks/{client_id}/skip {reason?}      → 200 CareTask     (treatment_step only; 400 task_not_skippable otherwise)
GET  /v1/plants/{plant_id}/courses                  → 200 Course[]     (one plan per plant, newest first, closed ones included)
GET  /v1/plants/{plant_id}/treatments               → 200 Treatment[]  (the per-problem history, newest first, steps in order, closed ones included)
POST /v1/plants/{plant_id}/water {amount_ml?, at?}  → 200 Plant        (the score does not move)
POST /v1/plants/{plant_id}/water/skip {reason}      → 200 Plant        (soil_wet|away|forgot — see below)
POST /v1/plants/{plant_id}/notes {chips, text?}     → 200 Plant        (a quick note, no photo; 409 plant_not_active when paused)
POST /v1/treatments/{id}/abandon {reason, note?}    → 200 Treatment    (too_hard|plant_recovered|other)
POST /v1/courses/{id}/abandon {reason, note?}       → 200 Course       (the same three reasons, every open problem at once)
PUT  /v1/plants/{plant_id}/schedule {…}             → 200 Plant        (frequency_days, next_water_amount_ml, check_in_interval_days, check_in_window_days, reminder_time "HH:MM", watering_reminder, check_in_reminder — all optional)
GET  /v1/plants/{plant_id}/care-plan                → 200 CarePlan
GET  /v1/plants/{plant_id}/history?range=7d|30d|90d → 200 HealthPoint[] {date, score|null, breakdown, provisional, care_score}  (one point per day; beat fills gaps)
GET  /v1/plants/{plant_id}/care-events              → 200 CareEvent[]  {id, type, title, detail, at}
GET  /v1/plants  ·  GET /v1/plants/{id}  ·  PATCH /v1/plants/{id} {nickname?, room?, indoor?, visibility?, light_status?, light_detail?}  ·  DELETE /v1/plants/{id}?keep_photos=true → 204
```

**Today's tasks** (`CareTask`). Four kinds, one list, ordered outstanding-overdue first, then
outstanding, then done, and by plant nickname inside each group. `id` is the client id you post
back: `task-water-<plantId>`, `task-cond-<plantId>`, `task-tstep-<stepId>` or
`task-env-<plantId>-<YYYYMMDD>`. A `watering` task waters the plant when completed; a
`condition` task is answered by the check-in flow (§3), and completing it just marks it done.
An **`environment`** task is written by the hourly weather sweep when the forecast crosses a
threshold (heat, cold, a dry heat run, dry air, a wet week): it carries its own `title` and
`detail`, which are the instruction the sweep wrote for that plant's placement, so render them
as they are. Completing one only marks it done — there is no plant state to change — it cannot
be skipped, and it drops off the list on its own when the day turns. A `treatment_step` is one
step of an open treatment plan (below). It carries `course_id` (which plan), `problem_id` and
`problem` (which problem, by taxonomy id and display name) — `problem_id: "all"` with
`problem: "All problems"` marks a step that serves every problem on the plan, and all three are
`null` on the other three kinds. One plant's steps arrive together in the plan's own order,
shared steps first, so a client that wants headings need only break on `course_id`.
Its `title` and `detail` are the step's own words, `overdue` is true once its due date has
passed, and it is the only kind that can be **skipped** — `POST
/v1/care/tasks/{client_id}/skip` with an optional `{"reason": "…"}` (≤ 200 chars). Skipping
records the reason, takes the task off today's list (`done: true`) and does **not** bring the
step back on its cadence; the step itself is then `skipped` rather than `done`, and it still
counts against `care_score` as care that was due. Anything else posted to `/skip` is `400
task_not_skippable`; a client id that is not on this owner's list today is `404 task_not_found`.

**Treatment plans** (`GET /v1/plants/{plant_id}/courses`). **A plant has one plan, not one
course per problem.** One photograph can find three problems; they become three `Treatment` rows
sharing one `course_id`, and this endpoint is those rows read as the plan they were prescribed
as. The whole history, newest first, closed plans included.

`Course` — `id, plant_id, status: open | closed` (open while **any** problem on it is),
`severity` (the worst problem's, `low|medium|high|null`), `started_at`, `review_at` (the earliest
open problem's), `closed_at: datetime|null`, `problems: CourseProblem[]`, `steps:
TreatmentStep[]`.

`CourseProblem` — `treatment_id` (the `Treatment` row, so `/treatments` and this endpoint can be
cross-referenced), `problem_id`, `problem`, `severity`, `tier`, `status` (the same six a
`Treatment` has), `added_at` (when this problem joined the plan — the same instant for everything
one scan found, its own day for one a later check-in added), `finding_id`, `review_at`,
`closed_at`, `abandon_reason`, `superseded_by_id`. **Worst problem first.**

`steps` is the **whole plan in one order**, already sorted: shared steps first, then the worst
problem's, then the protocol's own order. Each step is a `TreatmentStep` plus `problem_id` — a
taxonomy id, or the literal `"all"` for a step that serves every problem on the plan — which is
exactly the vocabulary `GET /v1/care/today` uses, so you need not join `treatment_id` back to
`problems[]`. `treatment_id` says which problem's row it hangs from and `serves` is the raw
column behind `problem_id`. **A step with `problem_id: "all"`** — "stand it away from the
others" — is one instruction however many pests prompted it: render it once, labelled for the
plan, and do not repeat it under each problem.

A plan holds at most **six steps due on any one day** and **fifteen outstanding at once**, both
counted over the whole plan: a problem joining a plan that is already full gets what is left of
the ceiling, and never fewer than one step. A problem found at
a later check-in **joins** the open plan rather than starting a second one, and the owner's only
notice of that is a `treatment_problem_added` care event. The owner can stop the whole plan with
`POST /v1/courses/{id}/abandon {reason, note?}` — the same three reasons, applied to every open
problem in one transaction (`404 course_not_found`, `409 course_not_open`).

**Treatments** (`GET /v1/plants/{plant_id}/treatments`). The per-problem view of the same rows,
unchanged, and still the place to answer "has this plant had thrips before, and what did we do?".
A treatment is one problem the plant has and the course prescribed for it. It is opened automatically — by the identification when a
plant is kept from a photo, and by any check-in that finds a problem — at most one open treatment
per problem per plant, and the endpoint returns the plant's whole history, newest first,
including closed ones.

`Treatment` — `id, plant_id, problem_id` (the taxonomy id, e.g. `pest.mealybug`), `problem` (its
display name, ready to show), `finding_id: uuid|null` (the finding it was opened from), `tier`
(1 first time, 2 for a problem that came back within 90 days), `status: active | improving |
escalated | resolved | superseded | abandoned`, `started_at`, `review_at` (the date the treatment
is meant to be judged), `expected_days_to_improve`, `recurrence: bool`, `closed_at: datetime|null`,
`abandon_reason: "too_hard"|"plant_recovered"|"other"|null` (only on an abandoned one — worth
showing beside the status, because "you stopped this" and "the plant got better" read very
differently in a history),
`course_id` (the plan this treatment is one problem of), `severity` (how grave the finding said
it was, `low|medium|high|null`),
`superseded_by_id: uuid|null` (the treatment that replaced this one — the only thing in the
list that says which course replaced which, so follow it to show "we tried this instead"),
`steps: TreatmentStep[]`.

`TreatmentStep` — `id, treatment_id, key, position, title, detail, due_at, cadence_days: int|null,
status: pending | done | skipped | superseded, done_at: datetime|null, skip_reason: string|null,
serves: "all"|null` (`null` means the problem of `treatment_id`).

Only `pending` steps due today or earlier appear on `GET /v1/care/today`; the rest are history
and future work. A step with a `cadence_days` repeats: completing it schedules the next one that
many days later, as long as that next date is still on or before `review_at` — so the list of
steps grows as the treatment goes on, each row records when it was really done, and no step is
ever due after the day the treatment is meant to be judged. Opening a treatment also shortens the plant's check-in
interval so a photo arrives before `review_at`, which is why `schedule.check_in_interval_days`
can change without the owner editing anything.

`superseded` is a step the **system** stopped asking for, because the treatment moved to a
stronger course. It is not a refusal — `skip_reason` is null and it counts for nothing in the
care score, unlike `skipped` — so show it as history, not as something the owner failed to do.

**A treatment is judged at every check-in.** The check-in reviewer is shown each open treatment
and says how it is going, and the treatment then moves on its own. Its `status` becomes
`resolved` (the problem is no longer visible; the plant's check-in interval goes back to what it
was before the treatment shortened it, unless another open treatment still needs it tighter),
`improving` (visibly better — same course, `review_at` pushed out), `escalated` (long enough to
have worked and it has not — `tier` goes up and a new set of `pending` steps appears while the
old ones become `superseded`), or `superseded` (the problem got worse: this course is closed with
a `closed_at`, and a **new** treatment for the same problem appears at the top of the list with
its own `started_at` and steps). When the reviewer is not confident enough, or it is simply too
early to say, nothing changes at all. The timeline carries one care event per outcome —
`treatment_resolved`, `treatment_extended`, `treatment_escalated`, `treatment_superseded`, and
`treatment_review_deferred` when the follow-up course could not be drafted and the review will be
tried again in three days.

So a client polling this endpoint after a check-in should expect a treatment's `status`, `tier`,
`review_at` and `steps` to have changed, and should render the list as the history it is: closed
courses and the one that replaced them, newest first.

**The owner can stop one** (`POST /v1/treatments/{id}/abandon {reason, note?}`). `reason` is
`too_hard`, `plant_recovered` or `other`, and the choice is not cosmetic: `plant_recovered`
closes the course as a *resolution* — the remaining steps stop counting against the care score,
the finding it was opened for is marked resolved, and the problem coming back inside ninety days
starts the next course at tier 2 — while `too_hard` records it as care that was asked for and
not given, and stops the same problem opening a new course for a fortnight. `other` is neither.
Either way the steps leave today's list, the check-in cadence the treatment shortened goes back,
and the treatment stays in the history with `status: "abandoned"`. Only an open treatment can be
abandoned (`409 treatment_not_open`); somebody else's id and an unknown id are the same `404
treatment_not_found`.

**The care plan** (`CarePlan`): `status`, `revision_id`, `trigger` (`identified | condition_update |
watering | item_overdue | weather | resumed`), `rationale` (why the plan changed), `latest_insight
{headline, body, tone}`, `items[]` (`kind: watering|treatment|environment|check_in|observe`,
`title`, `detail`, `cause`, `due_at`, `status: pending|done|skipped|superseded`,
`source_finding_id`, `replaces_item_id`), `schedule` (the plan's view of the watering/check-in
cadence) and `meta {attribution, timezone: the owner's}` — plan items and treatment steps are dated on
the owner's day, so the document and the field agree. The plan rewrites itself on its own: after a check-in,
when an item goes overdue (daily 06:00 UTC), when the weather forecast crosses a threshold (hourly),
and on resume. Show `trigger` + `rationale` as the "why this changed" line.

**A revision is now a diff.** It used to supersede every pending item, so an item could disappear
from under the owner because an unrelated revision ran. An item is now superseded only when the
revision replaces it — a new item names it in `replaces_item_id`, or a new item says the same
thing (same `kind`, identical `cause`) — or when the plan would hold more than six open items, in
which case the oldest by `due_at` go. Everything else keeps its `id` and its `status: pending`
across revisions, so a client may safely treat an item as a stable thing the owner is working on
rather than as a row that is replaced wholesale each time. `rationale` ends with
`" (kept N, superseded M)"`, which is a good "what changed" line on its own.

**Quick notes** (`POST /v1/plants/{id}/notes`). What the owner can tell us without a camera:
`{"chips": ["drooping", "dry_soil"], "text": "hot week"}`. At least one chip, no repeats, and
the vocabulary is `drooping · dry_soil · wet_soil · yellowing · leaf_drop · pests_seen ·
new_growth` (an unknown one is a 422). `text` is optional, at most 200 characters, and is never
parsed — it is for the reviewer and the timeline.

A note writes a `note` care event and, for every chip that names a problem, a **finding the
owner reported**. Those findings are deliberately weightless: they carry no severity and no
confidence, they do not move `health_score`, and they open no treatment. What
they do straight away is pull `schedule.check_in_window_opens` forward (to at most two days out,
never later than it already was) and, for `leaf_drop`, set `leaf_drop_reported`. `new_growth`
alone changes nothing but the timeline. The next check-in's reviewer is shown the reports and
either confirms one from the photo — at which point it picks up the matching finding's severity
and evidence — dismisses it, or leaves it standing for the check-in after. Posting to a paused
plant is `409 plant_not_active`; a **stale** plant takes notes normally.

**Skipping a watering** (`POST /v1/plants/{id}/water/skip`). The opposite answer to `water`, and
the three reasons mean three different things. `soil_wet` — the owner checked and the soil was
still damp — pushes `next_watering` two days out and counts as care **given**, so the task
leaves today's list. `away` and `forgot` change nothing at all: the watering is still due, the
task stays, and the event records that it was not done. Nothing here moves `health_score`, and
`last_watered` is untouched: nothing was watered.

**Plant fields that drive the UI:** `health_score` (1–100, or `null` when nothing has scored the plant yet — a paused plant keeps its number), `health_band`
(`thriving ≥ 70 · watch ≥ 40 · critical`, or `null` when paused or unscored), `care_status` (`active | stale | paused`),
`needs_attention` (true when paused, watering due, check-in due or leaf drop reported),
`schedule.next_watering`, `schedule.check_in_window_opens`, `streak_weeks`, `photo_count`.

**`stale` is new, and it is not `paused`.** A plant whose check-in window closes with no photo
goes `stale`: it keeps its `health_score`, its waterings are still due, its treatments still run
and its tasks still appear — all that has happened is that nothing current is known about it.
Missing a *second* window is what pauses it, and that is still the old behaviour (`health_score`
goes `null`, care freezes). So treat `stale` as active with a "we haven't seen this one lately"
hint, and do **not** offer `POST /resume` for it — that is `409 plant_not_paused`, deliberately,
because a stale plant comes back by being checked in on. The check-in that brings it back is
weighed at full confidence, so the health number can move further than usual on that one photo.

---

## 5. Flow 4 — Check in on a plant with a photo

```
POST /v1/photos (multipart, purpose=checkin, plant_id=<id>, file, framing, source, lat?, lon?)
                                                    → 202 {job_id, photo_id}   ← the job does NOT run yet
POST /v1/plants/{plant_id}/condition-updates
     {photo_id, user_verdict: healthy|concerns|needs_attention, observations?: string[] (≤10 × 160 chars), note?: string (≤1000)}
                                                    → 202 {job_id, update_pending: true}   ← this starts it
GET  /v1/analysis/{job_id}   (poll ~2 s, allow 3 min) → 200 AnalysisJob with `checkin` when done
```

The two-step shape is deliberate: the owner's own verdict is part of the analysis, so the photo
waits until it is posted. Errors on the POST: `404 plant_not_found` (not yours), `404 photo_not_found`
(not yours, not this plant's, or no check-in job for it), `400 photo_wrong_purpose` (an `identify`
photo), `409 photo_already_used` (already posted; a `failed` job may be re-posted).

**When `state == "done"`, read `checkin`:**

```json
"checkin": {
  "plant": { …full Plant with the new health_score… },
  "update": {
    "user_verdict": "healthy", "model_verdict": "needs_attention", "verdict_disagreement": true,
    "change_vs_last": "worse", "new_growth": false, "flowering": false,
    "score_before": 80, "score_after": 39, "note": "", "observations": ["one yellow leaf"], "created_at": "…"
  },
  "score_delta": -41, "next_check_in": "2026-10-07", "plan_revision_id": "…"
}
```

- `model_verdict` is what the photo shows; `user_verdict` is what the owner said. `verdict_disagreement` is true when they differ by more than one band — then the owner's verdict is dropped from the score rather than averaged in. Show both, and the flag as "our look at the photo differs from yours".
- `flowering` (new, `checkin.v2`) is true when the reviewer saw flowers or buds in the new photo; it feeds the home feed's `changes` card (§6b).
- `score_after` can never exceed the ceiling of `model_verdict`: 100 healthy, 69 concerns, 39 needs_attention.
- `plan_revision_id` is the care-plan revision this check-in triggered; refetch `care-plan` to show it. If the revision failed the check-in still lands: `plan_revision_id` is `null` and the job's `error` is unset — the plant keeps its previous plan.
- Findings the model saw (pests, disease, nutrient, abiotic) surface through the care plan's `treatment` items (`source_finding_id`), not through a separate endpoint.

---

## 6. Flow 5 — Insights, paused plants, account

```
GET  /v1/insights                                   → 200 {items[], correlation|null, meta {attribution, timezone: the owner's}}
POST /v1/plants/{plant_id}/resume                   → 200 Plant   (409 plant_not_paused on an active plant)
```

- `items[]` (`DailyInsight`): `day`, `kind` (`heat | low_humidity | rain | low_light_season`), `headline`, `body`, `tone` (`calm | heads_up | urgent`), `plant_ids[]` (the plants it applies to), `data` (the numbers behind it, e.g. `{"max_c": 36}`). Today plus the previous 29 days, newest first. Written by a nightly job (05:00 UTC), so a brand-new account has `[]` until the next morning; an account without a located photo has no home area and gets none.
- `correlation` (`{humid_weeks, dry_weeks, humid_mean, dry_mean, delta}`) compares the user's plants' average health in humid weeks (≥ 55 % RH) vs the rest; `null` until there are at least two weeks on each side.
- **Stale, then paused plants:** when a check-in window closes with no check-in, a nightly job (03:00 UTC) sets `care_status: "stale"` and adds a `check_in_missed` care event; the plant keeps its score and stays on today's list, and a check-in makes it `active` again. A **second** missed window sets `care_status: "paused"`. A paused plant **keeps its number** — `health_score` stays what it was — and only `health_band` becomes `null`; a `null` `health_score` means "never scored", not "paused". There is no endpoint that pauses a plant, and a stale plant cannot be resumed (409 `plant_not_paused`) — it comes back through a check-in. `resume` keeps the score the plant already had, opens a new check-in window, keeps the health history, and writes a fresh care-plan revision (`trigger: "resumed"`). Pausing also **removes the plant's outstanding `environment` tasks** dated today or later: a paused plant is one the system has stopped asking anything of, and a lone "move it away from the window" beside nothing else reads as a chore the owner still owes. Ones they already completed stay.

---

## 6b. Flow — Home screen

```
GET  /v1/home                                       → 200 HomeOut
```

One request for the whole home screen, computed on request and cached per user for an hour.
Every card is independent: a missing input (no home cell yet, no plants, a provider down) is
`null` or `[]` for that card, never an error for the rest. Any write that can change a card
refreshes the cache — a finished check-in, plant create/patch/delete/species correction, and a
located photo upload — so the screen is current right after the app's own action rather than
waiting out the hour; a plain re-open within the hour is served from cache.

```json
{
  "climate": {"kind": "tropical_humid", "label": "Tropical and humid", "mean_temp_c": 28.9,
              "mean_humidity_pct": 81, "rain_mm_30d": 142.0, "days": 30},
  "suggestions": [{"species": { "…Species…": "…" }, "reason": "Pet-friendly like everything you keep"}],
  "changes": [{"plant_id": "…", "nickname": "Monty", "kind": "flowering",
               "since": "2026-09-01", "count": 2, "detail": "Flowering since 1 Sep"}],
  "blooming_nearby": [{"scientific_name": "Gloriosa superba", "common_name": "flame lily",
                       "observations": 13, "photo_url": "…", "photo_attribution": "(c) …, CC BY-NC",
                       "species_id": null}],
  "meta": {"attribution": ["Weather data by Open-Meteo.com (CC BY 4.0)",
                           "Observations by iNaturalist community (CC BY-NC)"],
           "timezone": "Asia/Kolkata", "generated_at": "2026-09-25T09:00:00Z"}
}
```

- **`climate`** — the owner's local weather in one line of copy (`kind`, `label`) plus the
  30-day numbers behind it, or `null` without a home cell. `kind` is one of
  `tropical_humid | hot_dry | warm | cool | cold`.
- **`suggestions`** — up to five catalogue species the owner does not keep yet, each with the
  one-line `reason` it was picked; `species` is the full `Species` shape (§8).
- **`changes`** — what the owner's plants have done lately: `kind` is one of
  `new_growth | flowering | improved | worse`, `count` how many check-ins said so since
  `since`, and `detail` the sentence to print as-is. Empty until a check-in has landed.
- **`blooming_nearby`** — species iNaturalist saw flowering within about 50 km this month.
  `species_id` is set when it is a species we carry (tap through to its page), `null`
  otherwise — still worth showing, with its own photo and `photo_attribution`.
- **`meta.attribution`** — always both licence lines (Open-Meteo's, iNaturalist's), even when
  the cards they cover come back empty; render wherever the feed is shown. `meta.generated_at`
  is when the feed was computed, older than "now" on a cache hit.
- No coordinates or cell strings ever appear in the response — `climate` and `blooming_nearby`
  say what and how much, never where.

---

## 7. Endpoint reference

| Method | Path | Auth | Success | Purpose |
|---|---|---|---|---|
| GET | `/health` | public | 200 | Liveness `{status, version}` |
| POST | `/v1/auth/sign-up` | public | 202 | Start email sign-up (sends OTP) |
| POST | `/v1/auth/otp/request` | public | 204 | Send a 6-digit code (`purpose: signup|signin|reset`) |
| POST | `/v1/auth/otp/verify` | public | 200 | Verify code → TokenPair |
| POST | `/v1/auth/sign-in` | public | 200 | Email + password → TokenPair |
| POST | `/v1/auth/refresh` | public | 200 | Rotate refresh token → TokenPair |
| POST | `/v1/auth/sign-out` | auth | 204 | Revoke refresh token(s) |
| POST | `/v1/auth/password/reset` | public | 204 | Reset password with code |
| POST | `/v1/auth/oauth/{provider}` | public | 200 | Google/Apple id-token → TokenPair |
| GET | `/v1/me` | auth | 200 | Profile + stats |
| PATCH | `/v1/me` | auth | 200 | Update profile fields |
| PUT | `/v1/me/devices` | auth | 204 | Register push device |
| DELETE | `/v1/me` | auth | 204 | Delete account (soft) |
| GET | `/v1/species` | public | 200 | Browse catalogue: `q`, `traits` (indoor,low_light,beginner,pet_friendly), `cursor`, `limit` |
| GET | `/v1/species/suggest` | public | 200 | Typeahead: `q` (2–80 chars), `limit` (1–20, default 8) |
| POST | `/v1/species/resolve` | auth | 200/201 | Turn a picked suggestion into a `species_id` (201 = drafted) |
| GET | `/v1/species/featured` | public | 200 | Plant of the week |
| GET | `/v1/species/{species_id}` | public | 200 | Species detail |
| GET | `/v1/plants` | auth | 200 | My plants |
| POST | `/v1/plants` | auth | 201 | Add a plant `{species_id, photo_id?, nickname?, room?, indoor?}` |
| GET | `/v1/plants/{id}` | auth | 200 | Plant detail (with `care_score` and `risk`) |
| PATCH | `/v1/plants/{id}` | auth | 200 | Edit nickname, room, indoor, visibility, light |
| POST | `/v1/plants/{id}/species` | auth | 200 | Correct the plant's species `{species_id}` → full Plant |
| DELETE | `/v1/plants/{id}` | auth | 204 | Remove (`?keep_photos=true`) |
| GET | `/v1/plants/{id}/history` | auth | 200 | Health points (`range=7d|30d|90d`) |
| GET | `/v1/plants/{id}/care-events` | auth | 200 | Care timeline |
| GET | `/v1/plants/{id}/photos` | auth | 200 | Photos of the plant |
| POST | `/v1/plants/{id}/water` | auth | 200 | Mark watered `{amount_ml?, at?}` |
| POST | `/v1/plants/{id}/water/skip` | auth | 200 | Skip a watering `{reason: soil_wet\|away\|forgot}` |
| POST | `/v1/plants/{id}/notes` | auth | 200 | Quick note `{chips[], text?}` (409 `plant_not_active`) |
| PUT | `/v1/plants/{id}/schedule` | auth | 200 | Edit schedule and reminders |
| POST | `/v1/plants/{id}/resume` | auth | 200 | Resume a paused plant (409 if active) |
| POST | `/v1/plants/{id}/condition-updates` | auth | 202 | Start a check-in with an uploaded `checkin` photo |
| GET | `/v1/plants/{id}/care-plan` | auth | 200 | Current care plan |
| GET | `/v1/care/today` | auth | 200 | Today's care tasks |
| POST | `/v1/care/tasks/{client_id}/complete` | auth | 200 | Complete a task |
| POST | `/v1/care/tasks/{client_id}/skip` | auth | 200 | Skip a treatment step `{reason?}` (400 `task_not_skippable`) |
| GET | `/v1/plants/{id}/courses` | auth | 200 | Treatment plans for a plant, newest first |
| GET | `/v1/plants/{id}/treatments` | auth | 200 | Treatments for a plant, newest first |
| POST | `/v1/treatments/{id}/abandon` | auth | 200 | Stop a treatment `{reason, note?}` (404 `treatment_not_found`, 409 `treatment_not_open`) |
| POST | `/v1/courses/{id}/abandon` | auth | 200 | Stop a whole plan `{reason, note?}` (404 `course_not_found`, 409 `course_not_open`) |
| POST | `/v1/photos` | auth | 202 | Upload photo (`identify` runs at once; `checkin` waits for the condition update) |
| GET | `/v1/photos/{photo_id}` | auth | 200 | Photo metadata + signed URLs |
| GET | `/v1/analysis/{job_id}` | auth | 200 | Poll an identification or check-in job |
| GET | `/v1/insights` | auth | 200 | Daily insights + correlation |
| GET | `/v1/home` | auth | 200 | Home feed: climate, suggestions, changes, blooming nearby (§6b) |
| GET | `/v1/admin/metrics/problems` | **admin** | 200 | Per-problem accuracy and outcome rates (`?window_end=YYYY-MM-DD`; 403 `admin_only`) |

---

## 8. Key shapes

**Plant** — `id, kind, visibility, species: Species, nickname, room, indoor, added_on,
health_score: int|null, care_score: int|null, risk: Risk|null,
health_band: string|null, care_status (`active | stale | paused`), schedule: Schedule,
history: HealthPoint[] (90 d), care_history: CareEvent[] (last 20), photo_count, streak_weeks,
light_status, light_detail, leaf_drop_reported, needs_attention`

**HealthPoint** — `date, score: int|null, breakdown: object|null, provisional: bool|null,
care_score: int|null`

**Risk** — `level: "low" | "medium" | "high", reasons: string[], breakdown: object`

**Treatment** / **TreatmentStep** — see §4.

**`?include_v2` is gone**, and so are `health_v2`, `breakdown_v2` and the
`update.health_v2_*` fields. The score those names carried **is** `health_score` now; every
field below arrives on every response that has one to give. A request that still sends
`include_v2=true` is not an error — it is an unknown query parameter and is ignored.

`breakdown` is the working out behind a point's `score`: every number it was made of, so a
score can be explained without re-running anything. It is `null` on a point nothing scored (a
carry-forward day, anything before the scorer recorded one), and its shape is versioned —
`breakdown.version` — rather than frozen.

**`care_score` (0–100)** is how much of the care that was *due* over the last 30 days was
actually given on time — waterings and steps (treatment steps and plan items both) weighted 2
each, check-ins 1 — and it is 100, not 50, when nothing was due, because an owner who was asked
for nothing has kept every promise they were given; it is null on a day no sweep reached (it is
written nightly at 00:10 and again at each check-in), so read the plant's `care_score` rather
than the last point's. **`risk`** is
`{level, reasons}` about the *coming* week — a heatwave or an extreme day in the forecast, a
treatment step days overdue, a plant nobody has photographed in three weeks — where `reasons`
are short phrases meant to be shown as they are ("heatwave Tue–Thu", "no photo in 21 days"),
and `reasons` is empty exactly when `level` is `"low"`. Two of them are about the watering
*schedule*, and which one you get depends on whether the owner records waterings at all: with
at least two logged in the last sixty days, `"possible underwatering — 2 waterings missed"`;
without, and only once the watering is past due, `"no waterings logged in 31 days"`. An owner
who waters without opening the app must not be told they are neglecting a plant they are not.
`"possible underwatering — dry soil reported 2 times"` is independent of both: the owner felt
the soil, which owes the log nothing.

`risk.breakdown` carries every rule with its outcome, including the ones that did not fire; it
is for taking a level apart, not a display shape, and it may change without notice. A plant
nobody has photographed yet is dated from the day it was added, so a new plant is not at
risk for a photo it has had no chance to take. Risk is computed for the response and never
stored, so it appears on `GET /v1/plants/{id}` and on the `plant` inside a check-in
response — not on the list or the history — and it is `null` whenever it could not be
computed, which is why `level` and not the object's presence is what you branch on.

**Schedule** — `next_watering (date), next_water_amount_ml, frequency_days, last_watered, last_amount_ml,
check_in_interval_days, check_in_window_days, check_in_window_opens (date), watering_reminder,
check_in_reminder, reminder_time "HH:MM"`

**Species** — `id, number, common_name, common_names[], latin_name, tagline, summary, difficulty, light,
water, temperature, humidity, native_range, mature_height, growth_habit, toxicity, tags[], traits[],
common_issues[], care_tips[], image_url, default_care {watering_interval_days, water_amount_ml,
check_in_interval_days}, review_status (draft | reviewed)`

**AnalysisJob** — `job_id, photo_id, mode (identify | checkin), state, species|null, confidence|null,
rationale|null, alternatives[] {species|null, scientific_name, confidence}, initial_health|null
{verdict, observations[], severity}, checkin|null (§5), error|null, retryable, created_at, finished_at`

**CarePlan** — `plant_id, status, revision_id, trigger, rationale, latest_insight {headline, body, tone},
items[] CarePlanItem, schedule, meta {attribution, timezone}`

**Photo** — `id, purpose, plant_id, framing, source, width, height, captured_at, location_cell,
created_at, urls {original, working, thumb}` (signed, 15 min)

**Suggestion** — `source (catalogue | inaturalist), species_id|null, external_id|null, scientific_name,
common_name|null, matched_term` (always a species)

**ResolveOut** — `species_id, scientific_name, created (true when the species was drafted by this
call, which is also when the status is 201)`

**Me** — `id, name, email, city, units (metric | imperial), reminder_time, timezone (IANA name,
`"UTC"` until the app sets one), consent_training, created_at,
stats {plants_kept, under_active_care, average_health, care_streak_weeks}` — `under_active_care`
counts `active` **and** `stale` plants

**HomeOut** — `climate: ClimateOut|null, suggestions: NextPlantOut[], changes: ChangeOut[],
blooming_nearby: BloomOut[], meta {attribution, timezone, generated_at}` (§6b)

**ClimateOut** — `kind (tropical_humid | hot_dry | warm | cool | cold), label, mean_temp_c,
mean_humidity_pct, rain_mm_30d, days`

**NextPlantOut** (home feed — distinct from the typeahead **Suggestion** above) —
`species: Species, reason`

**ChangeOut** — `plant_id, nickname, kind (new_growth | flowering | improved | worse),
since (date), count, detail`

**BloomOut** — `scientific_name, common_name|null, observations, photo_url|null,
photo_attribution|null, species_id|null`

---

## 9. Error codes

| HTTP | `error.code` | App reaction |
|---|---|---|
| 400 | `otp_invalid`, `otp_expired`, `otp_locked` | show message; `otp_locked` → offer "send a new code" |
| 400 | `photo_wrong_purpose` | the photo was uploaded as `identify`; re-upload with `purpose=checkin` |
| 400 | `invalid_cursor`, `invalid_trait`, `invalid_time`, `oauth_email_required` | programming errors / show message |
| 401 | `unauthorized`, `invalid_token`, `token_expired` | refresh; if refresh fails → sign in |
| 401 | `token_reused`, `invalid_credentials`, `oauth_invalid` | sign in again |
| 403 | `email_unverified` | route to OTP verification |
| 404 | `plant_not_found`, `species_not_found`, `photo_not_found`, `task_not_found`, `treatment_not_found`, `course_not_found`, `care_plan_not_found`, `not_found` | stale local state → refetch list |
| 409 | `email_taken`, `account_deleted`, `plant_not_paused`, `plant_not_active`, `treatment_not_open`, `course_not_open`, `photo_already_used`, `conflict` | show message; `photo_already_used` → poll the existing job instead; `plant_not_paused` on a **stale** plant means check in rather than resume |
| 413 | `payload_too_large` | compress / pick another photo |
| 422 | `validation_error` (`details[]`) | fix the request |
| 422 | `invalid_timezone` | the tz database has no such zone; send an IANA name |
| 429 | `rate_limited`, `upload_quota_exceeded`, `analysis_quota_exceeded`, `budget_exhausted` | back off; quotas reset daily (UTC) |
| 429 | `species_draft_quota_exceeded` | that user has drafted their day's worth of new species; plants we already carry still resolve |
| 500 | `internal_error` | retry later |
| 503 | `species_draft_unavailable` | the species could not be drafted now (model or daily budget); offer a retry |
| job `failed` | `error` on the job, `retryable` | if `retryable`, re-post the condition update / re-upload |

---

## 10. Not built yet (do not code against these)

Nothing in the correction flow is on this list any more, and user time zones have gone too —
they are live (§1, `PATCH /v1/me {timezone}`). What is left is a flag and M4 work.

| Piece | Status | What it will be |
|---|---|---|
| Pl@ntNet pest/disease second opinion | built, **off** | Adds a "second opinion" hint to the check-in model when enabled; no API change. |
| Treatment-step and plan-item `due_at` in the owner's zone | **closed** | They are dated from the owner's day now, and the care plan's `meta.timezone` reports that zone like the other two documents'. Rows written before this change can still be a day early; nothing rewrites them, and they fall out of the plan on the next revision. |
| Push delivery of `check_in_missed` and insights | M4 | Device tokens are already accepted by `PUT /v1/me/devices`. |
| Community layer (public plants, feed) | M4 | `visibility: public` is stored but not served anywhere yet. |

**Admin only.** `GET /v1/admin/metrics/problems` is an operator endpoint and needs an account
with `role: "admin"`; anything else gets `403 admin_only` (and no token gets `401`). It answers
`{window_end, problems: [{problem_id, display, window_end, metrics}]}`, where `metrics` is what a nightly
job (04:00 UTC) made of the trailing 90 days per problem: `count`,
`verdict_disagreement_rate`, `note_confirm_rate`, `resolved_within_horizon_rate`,
`mean_days_to_resolve`, `abandon_rate`. **Every rate is `null` when its denominator was
zero** — render that as "—", never as 0 %. Pass `?window_end=YYYY-MM-DD` for one night;
without it you get each problem's most recent window, and the top-level `window_end` is the
newest of them. Nothing in the owner-facing app reads this.

Questions or gaps: open an issue in the repo, or comment on [`docs/openapi.json`](openapi.json) — it is regenerated from the code on every change, so it is the tie-breaker when this guide and the server disagree.
