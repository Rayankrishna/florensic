# Test server hand-off for the Flutter app

_Written 2026-10-07, updated 2026-10-19. Replaces the ngrok tunnel: the API now runs on a server, so the base URL is
fixed and images load without any tunnel._

## Base URL

```
http://13.202.212.73:8012
```

Plain HTTP for now (no certificate yet). Everything in [`frontend-api-guide.md`](frontend-api-guide.md)
applies unchanged: same routes, same shapes, same error codes. If you integrated against the
September guides, [`frontend-upgrade-guide.md`](frontend-upgrade-guide.md) is the list of what to
change.

Android blocks cleartext HTTP by default, so until the server has TLS the app needs this in
`android/app/src/main/AndroidManifest.xml` on the `<application>` tag (debug builds only):

```xml
android:usesCleartextTraffic="true"
```

and on iOS an `NSAppTransportSecurity` / `NSAllowsArbitraryLoads` exception in `Info.plist` for
debug builds. Remove both once the server is on HTTPS.

## Sign-in and sign-up screens: remove the demo credentials

The mock build pre-fills a demo account on the sign-in and sign-up screens and never sends the
form. Against the real backend both must start empty and submit for real:

- **Sign-in**: `POST /v1/auth/sign-in {email, password}` → tokens. Wrong password → `401
  invalid_credentials`. Keep-me-signed-in keeps the refresh token in secure storage and uses
  `POST /v1/auth/refresh`.
- **Sign-up**: `POST /v1/auth/sign-up {name, email, password}` → `202`, then the OTP screen with
  `POST /v1/auth/otp/verify {email, code}` → tokens. The name and password are sent on sign-up,
  not on verify. Existing email → `409 email_taken`.
- **Forgot password**: `POST /v1/auth/otp/request {email, purpose: "reset"}` then
  `POST /v1/auth/password/reset {email, code, new_password}`.
- Delete the hardcoded demo email/password constants and any "demo user" profile the locator
  injects; there is no demo account on the server, and no account survives the reset of
  2026-10-07.

## Signing in on the test server

OTP emails are now REALLY SENT (since 2026-10-19), from `Florensic <alerts@watchit.mydrop.art>`
— check spam the first time. Sign up with a real inbox you can open; a made-up address gets a
code nobody can read, because codes no longer appear in the API log. Once the account exists,
password sign-in works as usual. The database was reset on 2026-10-07, so create a fresh account.

## Showing a plant's photo

Every `Plant` (list, detail, create) carries its newest photo. On `GET /v1/plants` this is already
there for every item, so the grid needs no extra call per plant, and it is always the **latest**
photo of that plant: after a check-in the check-in photo replaces the identification photo.

```json
"cover_photo": {
  "photo_id": "…",
  "thumb":   "http://13.202.212.73:8012/v1/photos/<photo_id>/thumb",
  "working": "http://13.202.212.73:8012/v1/photos/<photo_id>/working",
  "captured_at": "2026-10-07T05:26:33Z"
}
```

`null` when the plant was kept without a photo. The gallery route `GET /v1/plants/{id}/photos`
and `GET /v1/photos/{id}` carry the same kind of links under `urls` (`original`, `working`,
`thumb`).

These links are **API routes, not public files**: the server streams the image only to its owner,
so the request must carry the bearer token like every other call.

```dart
// Plain Image widget
Image.network(
  plant.coverPhoto!.thumb,
  headers: {'Authorization': 'Bearer ${auth.accessToken}'},
  fit: BoxFit.cover,
);

// cached_network_image
CachedNetworkImage(
  imageUrl: plant.coverPhoto!.thumb,
  httpHeaders: {'Authorization': 'Bearer ${auth.accessToken}'},
  fit: BoxFit.cover,
);
```

Use `thumb` for cards and grids, `working` for the detail screen, `original` only for a
full-screen viewer. Rules:

- Do not persist these URLs across sessions; refetch the plant and use whatever it returns.
- A `401` on an image means the token expired: refresh the token and retry, the same as any call.
- A `404` means the photo is not this user's or was deleted.
- Use `cover_photo` for lists; call `/plants/{id}/photos` only on the detail or gallery screen.

## What is not on this server yet

Push notifications (tasks exist, nothing is sent), TLS, and the species catalogue list (empty until
seeded; identification still works because unknown species are drafted on the fly).

## If something looks wrong

Send the request, the response body and the time; the backend log is kept on the server.
