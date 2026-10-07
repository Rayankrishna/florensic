# Florensic

A living index of every plant you keep — and how each one is really doing.

This is the Flutter implementation of the **The Plant Gram** design
specification (`The Plant Gram.pdf`, the source of truth for every screen),
running against the Florensic API. The product is named **Florensic**; the
Dart package and Android application id still read `plant_gram`, so installs
and imports stay stable.
The frontend is fully functional against mock services: identification,
health scoring and weather are scripted stand-ins behind repository
interfaces, ready to be swapped for real APIs.

## Running

```sh
flutter pub get
flutter run                                   # against the Florensic API
flutter run --dart-define=API_BASE_URL=…      # against a deployed API
```

Backend wiring, what is live and what is still mocked:
[`doc/backend-integration.md`](doc/backend-integration.md).

After changing any `@observable` / `@action` / `@computed` code:

```sh
dart run build_runner build
```

## Tests

```sh
flutter test                    # smoke + store tests + screen goldens (macOS)
flutter test --update-goldens   # refresh goldens after a deliberate UI change
```

`test/screens_golden_test.dart` renders every designed screen at 390 × 844
with the bundled fonts and a pinned clock, so the app can be compared with
the specification page by page. Goldens only run on macOS (font rasterising
is platform-specific).

## Architecture

```
lib/
├── domain/
│   ├── core/            # HttpClient, TokenStore, JSON readers
│   ├── models/          # Plant, PlantSpecies, health, schedule, weather…
│   ├── provider/        # One provider per API area
│   └── repositories/    # Interfaces + remote implementations
│       └── remote/      # The API-backed repositories
├── interceptors/        # Request hooks (logging, latency) around the client
├── screens/             # One folder per flow (auth, home, plants, pokedex…)
├── shared/
│   ├── components/      # Buttons, cards, chips, sheets, rows, toasts
│   └── widgets/         # Painters: icon family, plant artwork, ring, charts
├── stores/              # MobX stores, one per responsibility
├── utils/               # Clock, dates, transitions, responsive helpers
├── enum.dart            # Shared enums (health bands, filters, statuses)
├── key.dart             # Storage + widget keys
├── locator.dart         # get_it wiring — swap mocks for real services here
├── main.dart
├── routes.dart          # Named routes + the app's screen transitions
├── storage_manager.dart # Typed SharedPreferences wrapper
└── theme.dart           # Design tokens: colour, type, spacing, radii, shadows
```

State management is **MobX** (`mobx` + `flutter_mobx`, codegen via
`mobx_codegen`). Dependency injection is **get_it** through `locator.dart`.

## Design system

All tokens come from the specification's Foundations page and live in
`theme.dart`, with one deliberate palette departure: the accent is a calm
leaf green `#7CB342` instead of the specification's neon lime, and dark
surfaces/headline text use a visible grey `#383E3B` rather than near-black,
and the whole type scale sits ~7% below the specification's.
Everything else follows the spec — ground `#F1F7F6`, signal colours with
their deep text pairs, 12/20/28/pill radii, a 4–32 spacing scale with a
20px gutter, wide green-tinted shadows. The bottom navigation is a liquid
glass pill: the page scrolls under a heavy backdrop blur. Type is Outfit
(display) and Plus Jakarta Sans (body), bundled under `assets/fonts/`
(OFL licences alongside).

The icon set is drawn in code (`shared/widgets/pg_icon.dart`) to the spec:
one family, 1.6px stroke, round caps, 24px grid. Botanical artwork is
painted per species (`shared/widgets/plant_artwork.dart`); the two tree
photographs under `assets/images/` are cut-outs extracted from the design
document and can be replaced one-for-one with final assets.

## Honest limitations

- **The app has no mock data.** Everything on screen comes from the API.
  Where the backend has no endpoint yet — the weather card, the environment
  chart and the notifications feed — the screen says so instead of showing
  invented numbers.
- **Sign-in is email + OTP only.** Google and Apple need platform SDKs to
  mint an `id_token`, so they are not offered.
- **iOS** has no target in this repo yet — the camera permissions are
  declared for Android only. See `doc/backend-integration.md`.
