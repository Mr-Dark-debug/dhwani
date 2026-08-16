# Dhwani Known Issues

Only verified unresolved limitations belong here. Resolved entries remain and are marked `RESOLVED`.

## 2026-08-17 — Android cold start stayed on native splash

Status: **RESOLVED**

Awaiting reminder plug-in initialization before `runApp` could stall a real cold install. Initialization is now idempotent and non-blocking for the first frame; reminder operations await the same future.

## 2026-08-17 — Landscape welcome overflowed by 36 pixels

Status: **RESOLVED**

The welcome screen now uses a scroll-safe two-column landscape composition. Re-inspected on the API 36 emulator with no overflow.

## 2026-08-17 — Akashvani Darbhanga upstream unavailable from Germany

Status: Open (upstream/network)

The current URL discovered from the official Akashvani live page reset TLS from the German test network. The older BitGravity discovery URL returned HTTP 404. Dhwani preserves the verified 1296 kHz metadata, performs bounded failover, and reports unavailable rather than false LIVE. Playback was independently verified with Radio Swiss Jazz.

## 2026-08-17 — Physical Pixel 10 not connected

Status: Open (test equipment)

Acceptance testing used `Dhwani_Pixel_10_Approx`, a Google Pixel-class Android 16/API 36 x86_64 AVD at 1280×2856 and 480 dpi. A physical Pixel 10 remains desirable for speaker audibility, Bluetooth hardware, OEM battery policy, launcher monochrome icon, and final lock-screen QA.

## 2026-08-17 — Scheduled capture requires a prepared user action

Status: Open (platform policy)

This release schedules visible alarm/recording reminders using inexact-while-idle delivery. Modern Android can block arbitrary unattended foreground-service starts, so Dhwani does not promise silent background playback or recording. Repeating-day schedules and guaranteed unattended capture are not claimed.

## 2026-08-17 — Release signing key unavailable

Status: Open (owner secret required)

Release APK/AAB compilation succeeds, but local release outputs use the Android debug certificate. A private upload/release keystore and protected credentials are required before store publication; they must not be generated as an unprotected repository secret or committed.

## 2026-08-17 — Automated environment cannot hear emulator speakers

Status: Open (test equipment)

Playback evidence includes network bytes, buffered audio, ICY metadata, active AudioTrack/media session, background continuation, and notification state transitions. Final subjective audibility should be confirmed on the physical phone.
