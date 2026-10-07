# Changelog

The health score has been rebuilt. **The cutover is below and it is breaking**; everything
under "Unreleased — health upgrade" after it is additive and arrived while the new scorer ran
in shadow beside the old one.

Dates are not given per entry on purpose — nothing here has shipped yet. The phases are the
branches in `docs/upgrade/00-map.md`, which is where the reasoning lives; this file is the
list of what a client can now call, read and expect.

## Breaking — health score cutover (migration 0020)

`health_score` is now computed by `app/modules/health/v2.py`. It is the same field in the same
place on the same responses, and it means something different: it is **what the photograph
showed, blended into what we already believed**, and nothing else moves it. The scorer it
replaces is deleted.

### What a number means now

| | Before | Now |
|---|---|---|
| A plant kept **without** a photo | 80 | `null` — nothing has scored it, and a number nobody measured is worse than saying so |
| A plant kept **from** a photo | 80 | the identification's own reading: 90 for a clean photo, less what its findings cost |
| A clean, healthy check-in | 70-ish, drifting with adherence | **90** — and 100 only for a clean photo that also improved and put out new growth |
| Logging a watering | **+1**, capped by the last photo's verdict | nothing. A watering is care *given* (`care_score`), not evidence about the plant |
| `POST /resume` after a pause | **70**, whatever the plant looked like | the score it already had. The returning check-in is believed outright instead |
| A pause | `health_score: null` | the number is **kept**; it is `health_band` that goes null |
| The owner's own verdict | ±3 on the score | recorded (`user_verdict`, `verdict_disagreement`) and scored nowhere |
| A treatment's reported effect | ±8 on the score | recorded; the course's own review acts on it |
| Adherence, weather | ±3 each | gone from the score. `care_score` is the owner's side; `risk` is the week ahead |

A check-in's answer is **blended**, not applied: a new score is `previous + alpha × (this
photo − previous)`, where alpha is how much this check-in is worth believing — `1.0` for a
high-severity finding or a drop in verdict band, `0.4` for a photo the reviewer could barely
read (and then `provisional: true`), `0.7` otherwise. So one bad photograph moves a plant part
of the way, not all of it, and a plant coming back after a gap is believed outright.

### Fields

- **`?include_v2` is gone**, from `GET /v1/plants/{id}`, `GET /v1/plants/{id}/history` and
  `GET /v1/analysis/{job_id}`. Sending it is not an error — it is an unknown query parameter
  and is ignored. Everything it used to gate now arrives on every response: `care_score`,
  `risk`, and a health point's `breakdown` and `provisional` — with one exception, and it is
  wider than one route. **`risk` is computed on `GET /v1/plants/{id}` and on the `plant`
  inside a check-in response, and is `null` everywhere else a plant is returned**: the list,
  the history, and the care actions that hand back a plant (create, patch, species correction,
  water, water/skip, notes, resume, schedule edit). It is four queries per plant, so only the
  two responses whose job is to describe one plant pay for it. On the others a null `risk`
  means "not computed here" rather than "nothing coming" — so do not clear a risk banner off
  a watering's response; refetch the detail.
- **`health_v2`, `breakdown_v2` and `update.health_v2_before/after/alpha/provisional` are
  gone.** Their values are what `health_score`, `HealthPoint.breakdown` and
  `update.score_before/score_after/alpha/provisional` now carry.
- **`HealthPoint.breakdown`** (was `breakdown_v2`) is every number the day's `score` was made
  of, so a score can be explained without re-running anything. `null` on a day nothing scored
  — a carry-forward, or any day before the scorer recorded one. The shape is versioned
  (`breakdown.version`, currently 1) rather than frozen:

  ```json
  {
    "version": 1,
    "condition": {
      "verdict": "concerns", "base": 90,
      "findings": [{"type": "abiotic", "severity": "medium", "penalty": 30}],
      "penalty_max": 30, "penalty_others": 0.0, "penalty": 30,
      "after_penalty": 60, "floor": 40, "ceiling": 69, "score": 60
    },
    "trend": {"value": "worse", "delta": -6},
    "new_growth": {"value": false, "delta": 0},
    "raw": 54,
    "alpha": {"value": 0.7, "reason": "default"},
    "photo_quality": 1.0, "provisional": false,
    "previous_health": 70, "health": 59
  }
  ```

  `raw` is what this photograph said on its own; `health` is that blended into
  `previous_health` at `alpha`. `alpha.reason` is one of `default`, `high_severity`,
  `band_dropped`, `low_quality`, `treatment_worsening`, `resumed`, `stale_return`,
  `long_gap`.
- **`provisional`** (on a health point, and on a check-in) is true when the photograph was too
  poor to read: the number is a guess held lightly, and the next usable photo is believed
  outright. A carry-forward point on a **stale** plant is provisional too.
- **`health_band` is nullable.** The three names are unchanged — `thriving` ≥ 70, `watch`
  ≥ 40, `critical` below — and the fourth, **`"paused"`, is gone**: a paused plant now reads
  `{"care_status": "paused", "health_score": 72, "health_band": null}`, because the number is
  the last thing anybody knew rather than a current claim. A plant nothing has ever scored
  reads `health_band: null` as well. Switch on `care_status` for the paused case and render no
  band when `health_band` is null.
- **`update.score_before` can be `null` with `score_after` set**: a plant's first scored
  check-in had nothing to blend into. `checkin.score_delta` is `null` for the same reason,
  where it used to be a number on every check-in.
- **A check-in the new scorer never scored has `score_before` *and* `score_after` null** —
  every check-in recorded before migration 0014, and any whose scoring failed. 0020 copies
  that pair unconditionally (which is what makes its downgrade exact), so such a row loses the
  number it used to publish and its `score_delta` goes null with it. Nothing has shipped, so
  the population is development and smoke databases; the retired scorer's numbers for those
  rows are in `score_before_legacy`/`score_after_legacy` until those columns are dropped.
- **`stale`** (`care_status`, since Phase 6) sits between `active` and `paused`: one missed
  check-in window. Its score stands, its band stands, its waterings are due and its treatments
  run — and `POST /resume` on it is `409 plant_not_paused`, deliberately, because it comes back
  by being checked in on.
- **`CareTask.kind`** is `watering | condition | treatment_step | environment`. A client that
  switches on `kind` must tolerate a value it does not know.

- **`GET /v1/me`'s `stats.average_health` and the home feed's suggestions average only the
  plants you are **caring for**.** A paused plant keeps its number (above) and is out of the
  average: the figure is the last thing anybody knew rather than a reading of now, and before
  the cutover the pause nulled the score so the average dropped it anyway. A **stale** plant is
  in — its care has not stopped. The home feed's `easy` suggestion factor reads the same
  average, and its threshold is now the **thriving floor (70)** rather than the 60 that was
  calibrated against the retired scale.

### Behind the API

- `plants.health_score_legacy`, `health_points.score_legacy` and
  `condition_updates.score_before_legacy/score_after_legacy` hold what the retired scorer last
  said. They are in no response, they are read only by `scripts/compare_health.py`, and they
  are **dropped — with that script — no earlier than thirty days after the deploy that applies
  0020, earliest 2026-11-01**.

### Known after the cutover

- `GET /v1/me`'s `stats.average_health` is `0`, not `null`, for an owner none of whose plants
  under care have been scored yet — including an owner whose only scored plant is **paused**:
  the field is an `int` and has coalesced a missing average to zero since M1.
- A plant's whole day is still one `health_points` row, so a day with several check-ins draws
  one point — the last one. `docs/upgrade/00-map.md` §16 has the rest of the list.

## Fixed after the final audit (`upgrade/8-audit-fixes`)

- **`risk` now sees treatments.** Since Phase 4 a course lives in `treatments`/`treatment_steps`,
  and risk kept reading only care-plan items — so a plant with three open courses and eight
  pending steps reported `active_treatments: 0` and could never show `"treatment step N days
  overdue: …"` or the "treatment running, no photo in 7 days" reason. Both reasons can appear
  again. No change to the response shape: `risk` is still `{level, reasons, breakdown}`.

- **One treatment plan per plant, not one per problem.** A scan that found three problems used
  to open three separate courses with eight steps all due the same day, instructions that
  contradicted each other, and a `care_score` of 0 on a plant minutes old. Those rows are now
  **members of one course**, and everything about the change is additive — nothing was removed
  or renamed, and every treatment that already exists is a course of one.

  | What | Where |
  |---|---|
  | `GET /v1/plants/{id}/courses` | New. Every plan this plant has had, newest first: `{id, plant_id, status, severity, started_at, review_at, closed_at, problems[], steps[]}`. `problems[]` is worst first; `steps[]` is the whole plan in one order — shared steps first, then the worst problem's — and each step carries `problem_id` (a taxonomy id, or `"all"`), the same vocabulary today's list uses. Closed plans are kept |
  | `POST /v1/courses/{id}/abandon` | New. Stops every open problem on the plan in one transaction, same `{reason, note}` body as the per-treatment route, which stays. 404 `course_not_found`, 409 `course_not_open` |
  | `GET /v1/plants/{id}/treatments` | Unchanged, plus `course_id` and `severity` on each treatment and `treatment_id` and `serves` on each step |
  | `GET /v1/care/today` | A `treatment_step` task gains `course_id`, `problem_id` and `problem`. `problem_id: "all"` (`problem: "All problems"`) marks a step that serves every problem on the plan — show the label, do not show the step twice. All three are `null` on a watering, a check-in and an environment task. One plant's steps arrive grouped by plan |
  | `CareEvent.type` | Adds `treatment_problem_added` — a problem found at a later check-in joined the plan the plant was already on. It is the owner's only notice, since nothing pushes |

  Two caps now bound a plan, both counted over the **whole plan** rather than over the scan
  that added to it: at most **six steps due on any one day** (the overflow is re-dated to the
  next day with room, never past that problem's review date) and **fifteen outstanding at
  once**. A problem joining a plan that is already full gets what is left of the ceiling, and
  never fewer than one step. And a step is no longer counted against the owner's `care_score` on the day it was
  created — the care window ends before today, so a step written this morning is on today's
  list and is not yet care withheld.

  **`care_score` is a number on a plant that has just been added.** It used to be `null`
  until a nightly sweep wrote the plant's first health point, because the field is read off
  the latest stored point — so a plant seconds old said "we do not know how you are doing" on
  the one screen where the owner had done nothing wrong. `GET /v1/plants/{id}` and the plant
  inside a check-in response now compute it on read wherever no stored point carries one, from
  the same window the sweep uses, which for a new plant is **100** ("nothing was due"). A
  stored number always wins, and the **list** route still does not compute it (`risk`'s rule,
  for `risk`'s reason), so `care_score` is still `null` on `GET /v1/plants`.

  **Every timestamp a write hands back is UTC.** `POST /v1/care/tasks/{id}/complete` and
  `/skip`, `POST /v1/plants/{id}/water`, `/water/skip`, `/notes` and `/resume`, and both
  abandon routes, used to render the instant they had just written in the **owner's**
  offset (`2026-10-06T15:17:38+05:30`) while the next read of the same row said `Z`
  (`2026-10-06T09:47:38Z`). Same instant, two renderings, from two calls about one row — a
  client that diffs what it was handed against what it refetches saw the field change, and
  one that parses naively was hours out. Every stored instant is now normalised where it
  is assigned, so `done_at`, `last_watered` and a care event's `at` read the same from the
  write as from the read. The owner's **day** is unchanged and still decides every date:
  when the next watering falls, when a check-in window opens, which day a task is on.

  **A check-in reviews at most six problems.** The reviewer is shown — and may answer about —
  six open treatments, which is `checkin`'s own schema limit on `treatment_reviews`. It used to
  be a cap on *courses*, back when each problem opened one; it is now a cap on **members**, so a
  plant with a seventh open problem has that one judged by nobody until something ahead of it
  closes. Nothing in the response says which were reviewed; a client should not read an
  unchanged `status` as "the reviewer looked and saw no change".

## Unreleased — health upgrade (additive, behind `include_v2` until the cutover above)

Everything below arrived after `upgrade-1` branched from `2cf1e24`, while the new scorer ran in
shadow. The `include_v2` flag the entries mention is gone; where they describe a `health_v2*`
field, read the cutover section above for the name it has now.

### Endpoints

| Endpoint | What it does | Phase |
|---|---|---|
| `POST /v1/plants/{id}/notes {chips, text?}` | A quick note with no photo: one or more chips from a fixed vocabulary, optional free text. 409 `plant_not_active` on a paused plant | 6 |
| `POST /v1/plants/{id}/water/skip {reason}` | "I did not water it, and why" — `soil_wet \| away \| forgot`. Only `soil_wet` moves the schedule (+2 days from today); a paused plant is 409 `plant_not_active` | 6 |
| `GET /v1/plants/{id}/treatments` | Every treatment this plant has had, newest first, with its steps | 4 |
| `POST /v1/treatments/{id}/abandon {reason, note?}` | Stop a course: `too_hard \| plant_recovered \| other`. 404 `treatment_not_found`, 409 `treatment_not_open` | 6 |
| `POST /v1/care/tasks/{client_id}/skip {reason?}` | Skip a treatment step. 400 `task_not_skippable` for any other kind | 4 |
| `GET /v1/species/suggest`, `POST /v1/species/resolve` | Typeahead over the catalogue and iNaturalist, and turning a pick into a `species_id` (drafting a care card when we have never seen it) | M3c |
| `GET /v1/admin/metrics/problems` | Operator-only: per-problem accuracy and outcome rates. 403 `admin_only` | 7a |

### Fields

- **`?include_v2=true`** on `GET /v1/plants/{id}`, `GET /v1/plants/{id}/history` and
  `GET /v1/analysis/{job_id}` added `health_v2`, `care_score`, `risk {level, reasons,
  breakdown}` and the per-point `health_v2`/`care_score`/`provisional`. **Gone at the
  cutover**: those fields arrive unasked now, under the names the section at the top gives.
  (2, 2b, 3)
- **`timezone`** on the profile (`GET`/`PATCH /v1/me`), an IANA name, default `"UTC"`; an
  unknown one is `422 invalid_timezone`. (6)
- **`meta.timezone`** on the home feed, the insights feed and the care plan tells you which
  calendar that document's dates are on. All three report the owner's zone — the care plan's
  said `"UTC"` until its items were dated on the owner's day. (6, 7a)
- **`CareTask.kind`** gained `treatment_step` (4) and `environment` (6). A client that
  switches on `kind` must tolerate a value it does not know.
- **`Plant.care_status`** gained `stale`: one missed check-in window no longer pauses a
  plant, it marks it as something nothing current is known about. Its scores stand, its
  waterings are due, its treatments run. A second missed window pauses it — which since the
  cutover keeps the number and drops the band rather than nulling the number. (6)
- **`Treatment.superseded_by_id`** and `abandon_reason`. (5, 6)
- **`Finding.source`** (`model | note`), with `dismissed_at`, `resolved_at` and
  `confirmed_by_id` for a report the check-in reviewer answered. (6)
- **`Finding.problem_id`**, `raw_name`, `problem_method`, `problem_confidence`: findings are
  normalised to a 40-entry taxonomy. (1)
- `CareEvent.type` gained `watering_skipped`, `note`, `treatment_opened`,
  `treatment_resolved`, `treatment_extended`, `treatment_escalated`,
  `treatment_review_deferred`, `treatment_abandoned`. (4, 5, 6)

### Behaviour

- **Every date is the owner's day**, in the zone on their profile: today's task list, a
  watering's due date, a check-in window, an insight's `day`, and — since 7a — a plan item's
  and a treatment step's `due_at`. Timestamps are still UTC instants. (6, 7a)
- **Treatments.** A finding with a real severity opens a course of dated steps from a
  protocol, personalised by the text model with the protocol's own wording as the fallback.
  The steps appear on `GET /v1/care/today` as `treatment_step` tasks and count toward the
  care score. The check-in reviewer judges each open course and the system resolves, extends,
  escalates or replaces it. (4, 5)
- **Quick notes** pull the next check-in forward by up to two days and are shown to the next
  reviewer, who confirms or dismisses them. An unconfirmed note scores nothing — it is a
  report, not a diagnosis — but it does raise `risk`. (6)
- **A weather crossing leaves a task**, not only a care-plan revision, and there is a `cold`
  rule at 8 °C for every plant. A pause removes the plant's outstanding environment tasks
  (7a). (6, 7a)
- **Under-watering risk** only fires for an owner who logs waterings (two in sixty days);
  otherwise, once the watering is past due, the reason is "no waterings logged in N days". An
  owner who waters without recording it is not told they are neglecting a plant. (7a)
- **Nightly jobs** gained `care.problem_metrics` (04:00 UTC), which writes the per-problem
  rates the admin endpoint serves and fills in `training_data.outcome_7d/14d`. (7a)

### Prompts

`identify.v2` (typed findings), `checkin.v3` (photo quality), `checkin.v4` (treatment
reviews), `checkin.v5` (owner reports), `careplan.v3`, `problem_normalise.v1`,
`treatment_personalise.v1`/`v2`. Every earlier version is still on disk and unchanged; the
pipeline runs the newest of each.

### Migrations

`0011`–`0020`. Each has a full downgrade and an up/down test. `0019` drops
`plants.health_v2_reset_pending`, adds `problem_metrics`, and turns
`training_data.outcome_7d/14d` from `String(10)` into `Integer`. `0020` is the cutover above:
it moves the new scorer's columns into the canonical ones, keeps the old values beside them in
`*_legacy`, and its up/down test runs the trip **with data**.

### Removed

The `include_v2` flag and the `health_v2*` fields — see the cutover section at the top for
what replaced them — and, before that, three internals with the user's say-so:
`app.core.time.today_utc()` (every date is a person's date now), the
`plants.health_v2_reset_pending` column (a rule over the plant's own history replaced it) and
the first scorer itself (`care/scoring.py::score_from_observation`, `NEW_PLANT_SCORE`,
`RESUME_SCORE`, `apply_watering`'s +1, the adherence and weather terms, the owner's own
scoring term and the per-verdict ceiling).
