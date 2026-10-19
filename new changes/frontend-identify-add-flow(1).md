# Identify and add: the new flow

_Written 2026-10-16 for the Florensic Flutter app; the add's staged progress added 2026-10-19. The identification pipeline was rebuilt for
speed and the add call changed shape. This is the one document to work from for the scan → add →
correct flow; [`frontend-api-guide.md`](frontend-api-guide.md) stays the full reference and
[`frontend-upgrade-guide.md`](frontend-upgrade-guide.md) §2 has the same changes as a
before/after table. Everything here is live on the test server._

## What changed in one look

| | Before | Now |
|---|---|---|
| Identification wait | 10–60 s | **~5 s** (measured 3.0–4.9 s) |
| Identify result on a plant we don't carry | drafted a species, slow | **`species.id: null`** + `scientific_name`, instant |
| `POST /v1/plants` body | `species_id` required, `photo_id` optional | **`photo_id` required, `species_id` optional** |
| Correcting a wrong identification | resolve took ~10 s | resolve answers in **milliseconds** |
| `no_confident_match` | possible job state | switched off — you will not see it |
| Own check-in photo sent to add | `404 photo_not_found` | **`409 photo_not_identification`** |
| `POST /v1/plants` wait | 7–30 s, spinner | **~1 s**, then a narrated setup (2026-10-19, below) |

## Flow A — scan and keep (the normal path)

**1. Upload.**

```
POST /v1/photos   multipart: file, purpose=identify, framing, source, lat?, lon?
→ 202 {job_id, photo_id}
```

Keep `photo_id`. You will need it for the add — it is now the one required field.

**2. Poll until done.** Every second is fine; nothing finishes faster than ~3 s.

```
GET /v1/analysis/{job_id}
→ {state, species, scientific_name, confidence, alternatives[], initial_health, findings[]}
```

- `state` goes `queued → running → done | failed`. Treat `no_confident_match` as unreachable.
- `scientific_name` is **always present** on a finished identification. New field, use it for the
  headline.
- `species` is the catalogue card when we carry the plant, and **`null` when we do not**. A null
  species is NOT an error and NOT "unknown plant": the name and confidence stand; only our
  catalogue entry does not exist yet. Render the result exactly the same either way.
- Show `confidence` as returned. There is no second opinion behind it any more.

**3. The user taps Keep.**

```
POST /v1/plants {photo_id, nickname?, room?, indoor?}
→ 201 Plant
```

**Do not send `species_id` here.** Omitting it means "keep it as whatever the scan said", and the
server creates the catalogue entry itself when it has to.

The 201 comes back in **about a second** with the plant's database half: the species, the score
anchored from the scan, its problems, `cover_photo` — open the plant page straight away. What it
does **not** have yet is the slow half: the treatment course (when the findings carried a severity)
and the first care plan. Those are drafted behind the response by a **setup job**, and the 201
carries one extra block to watch it with:

```
"setup": {"job_id": "…", "state": "queued", "stages": []}
```

**4. Narrate the setup.** Poll about once a second until `state` is `done` or `failed`:

```
GET /v1/plants/{plant_id}/setup
→ {job_id, state, stages: [{stage, message, at, data?}]}
```

Render the newest stage's `message` in a one-line strip on the plant page — it is written for the
owner and meant to be shown verbatim. A sick plant reads:

| `stage` | example `message` | `data` |
|---|---|---|
| `opening_treatment` | Problem found — creating a treatment for mealybugs… | `{problems: ["Mealybugs"]}` |
| `treatment_ready` | Treatment ready, 5 steps | `{courses, steps}` |
| `drafting_plan` | Writing the care plan… | — |
| `plan_ready` | Care plan ready | `{revision_id}` |
| `plan_failed` | Couldn't write the care plan just now — it will be tried again | `{error}` |
| `done` | Done | — |

A healthy plant has no treatment lines. `plan_failed` is not a failure of the setup: the job still
ends `done`, the plant is fully usable, and the plan is written at the next revision trigger.
`state: failed` (a final `failed` line) is rare and also leaves the plant usable.

**`done` is the refetch signal.** The course arrives behind the poll now: on `done`, refetch
`GET /v1/plants/{id}/courses`, `GET /v1/plants/{id}/care-plan` and `GET /v1/care/today`. A course
read immediately after the 201 is legitimately empty for a few seconds. Expect `done` ~5 s after
the 201 for a healthy plant and 10–25 s for one that needs treatment. A setup that stays `queued`
means the worker is behind; keep polling or stop after a minute and refetch later — nothing is
lost.

## Flow B — the scan is wrong and the user knows better

Same steps 1–2. The user disagrees with the name, so before keeping:

**3. Typeahead** as they type (debounce ~300 ms):

```
GET /v1/species/suggest?q=...
→ {items: [{source, species_id, external_id, scientific_name, common_name, matched_term}]}
```

**4. Resolve the row they tapped** — send it back exactly as received:

```
POST /v1/species/resolve {source, species_id?, external_id?, scientific_name, matched_term}
→ 200/201 {species_id, scientific_name, created}
```

This now answers in milliseconds (it used to block ~10 s). The profile is filled in by a
background job afterwards; nothing for the app to wait on.

**5. Keep, with the correction:**

```
POST /v1/plants {photo_id, species_id, nickname?, ...}
→ 201 Plant
```

Sending `species_id` **is** the correction. The same photo still anchors the health score and the
findings; the chosen species drives the care plan; the disagreement is recorded for training
automatically. No separate "correct species" call is needed before the plant exists.

(`POST /v1/plants/{id}/species` still exists for correcting a plant that was already added.)

## Flow C — the photo was not a plant

The job still ends `done`, usually with a low confidence and a rationale. If the user keeps it
anyway, the add answers `400 species_name_unusable` when the identification named nothing. Offer
the typeahead (Flow B) or a retake.

## Errors on `POST /v1/plants`, complete

| Status | code | Meaning | What the app does |
|---|---|---|---|
| 422 | `validation_error` on `photo_id` | the field is missing — it is required now | always send the identify photo's id |
| 409 | `identification_not_ready` | the job hasn't finished | poll the job, then retry |
| 409 | `identification_failed` | the job failed | do not loop — retake, or pick a species and send `species_id` |
| 409 | `photo_not_identification` | a check-in photo was sent | use the `purpose=identify` photo. **This answered `404 photo_not_found` before** — update any 404 match |
| 409 | `identification_no_match` | only if no-match is ever re-enabled server-side | show the typeahead, send the pick |
| 400 | `species_name_unusable` | the scan named nothing | typeahead or retake |
| 409 | `photo_already_used` | that photo already made a plant | poll/open the existing plant |

## What to change in the app, checklist

- [ ] Make `photoId` required and `speciesId` optional in the add-plant request model; delete any
      add path that has no photo.
- [ ] Read `scientific_name` off the job result and stop treating `species: null` as a failure.
- [ ] Remove any handling that waited on `no_confident_match`.
- [ ] Rewire the correction screen: resolve, then add with `speciesId` + the same `photoId`.
- [ ] Swap the 404 match on add-with-check-in-photo for `409 photo_not_identification`.
- [ ] Add the three `identification_*` codes and `species_name_unusable` to the add call's error
      handling, per the table above.
- [ ] Shorten the identify spinner copy: ~5 s, not up to a minute.
- [ ] Drop the add spinner: open the plant page on the 201, poll `GET /v1/plants/{id}/setup`
      every ~1 s, show the newest stage's `message` in a strip, stop on `done`/`failed`.
- [ ] On setup `done`, refetch the plant's courses, care plan and today's tasks.

Nothing else moved: auth, polling shape, photos and `cover_photo`, tasks, treatments and the home
feed are all exactly as documented in the main guide. Check-ins gained one additive field: the
poll's `progress[]` narrates them the same way (`reading_photo`, `scored` with `{score, delta}`,
`reviewing_treatments`, `revising_plan`, then `done`/`failed`) — see the main guide, Flow 4.
