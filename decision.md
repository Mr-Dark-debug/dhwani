# Dhwani Engineering Decision Journal

This journal is append-only. Superseded decisions remain as historical evidence.

## DEC-0001 — Product architecture and delivery sequence

Date: 2026-08-16
Status: Accepted

### Question
How should a broad, production radio application be delivered without turning the codebase into a single coupled prototype?

### Options considered
- A screen-first prototype followed by service integration
- A native Android-only implementation
- A feature-oriented Flutter application built in vertical, testable slices

### Research / evidence
- The requested acceptance target is Android while Windows support remains desirable.
- Playback, persistence, recording, catalogue access, and platform services need independently testable boundaries.
- The supplied product brief is the approved design and acceptance specification.

### Decision
Build a feature-oriented Flutter application directly in this repository. Establish typed domain contracts and platform services first, then deliver onboarding/catalogue, player, saved/history/custom stations, recordings, timers, settings, and Android integration as working vertical slices.

### Why
This keeps platform-specific work isolated while preserving a single responsive UI and enables deterministic unit/widget tests around the failure-prone logic.

### Trade-offs
- More focused files and interfaces than a small prototype.
- Some Android capabilities require platform channels or services even when most UI is shared.

### Revisit if
Flutter or a required maintained dependency cannot meet modern Android media-session or recording requirements.

## DEC-0002 — Visual direction

Date: 2026-08-16
Status: Accepted

### Question
What visual system should distinguish Dhwani while preserving the supplied reference's strengths?

### Options considered
- Literal vintage radio styling
- Standard Material component styling
- Editorial precision: warm paper surfaces, near-black typography, calibrated red, and a custom kinetic tuner

### Research / evidence
- The brief explicitly rejects retro skins, grey presentation canvases, generic tutorial styling, and excessive colour.
- The reference emphasizes large frequency typography, whitespace, a fixed red needle, and fine tuner marks.

### Decision
Use a restrained editorial radio aesthetic with warm off-white and charcoal themes, a single warm-red signal accent, tabular frequency numerals, generous whitespace, and a custom-painted tuner whose scale moves beneath a fixed needle.

### Why
It feels modern and emotionally grounded while giving the product a memorable, functional hero interaction.

### Trade-offs
- Requires custom rendering and more visual QA than stock widgets.
- Typography and spacing need explicit responsive constraints.

### Revisit if
Large-text accessibility or compact-landscape testing requires a denser alternate player layout.

## DEC-0003 — State, routing, persistence, and networking

Date: 2026-08-16
Status: Accepted

### Question
Which maintained foundations provide observable state, navigation, structured storage, and resilient HTTP?

### Options considered
- Provider, Navigator 1, preferences, and `http`
- Bloc, auto_route, Isar, and Chopper
- Riverpod, GoRouter, Drift, SharedPreferences, and Dio

### Research / evidence
- Pub.dev on 2026-08-16: `flutter_riverpod` 3.4.2, `go_router` 17.5.0, `drift` 2.34.3, `drift_flutter` 0.3.1, `shared_preferences` 2.5.5, and `dio` 5.11.0.
- GoRouter is maintained by the Flutter team.
- Drift provides typed SQLite and avoids the end-of-life `sqlite3_flutter_libs` path.

### Decision
Use Riverpod for state/dependency injection, GoRouter for navigation, Drift for structured records/cache, SharedPreferences only for small settings, and Dio for bounded/cancellable requests.

### Why
The stack is current, cross-platform, testable, and keeps UI independent from storage and remote data sources.

### Trade-offs
- Drift requires generated code.
- Riverpod 3 differs from older tutorials, so code follows its current API.

### Revisit if
A dependency blocks Android 16 or Windows builds.

## DEC-0004 — Playback and background media

Date: 2026-08-16
Status: Accepted

### Question
How should one playback authority cover radio formats, Android controls, focus, and truthful state?

### Options considered
- Native Media3 behind a method channel
- `just_audio_background`
- `just_audio` + `audio_service` + `audio_session`

### Research / evidence
- `just_audio` 0.10.6, `audio_service` 0.18.19, and `audio_session` 0.2.4 were released June 29, 2026 by the same established maintainer.
- `audio_service` supports background audio, notification/lock-screen/headset controls, queue navigation, and Android Auto media browsing.
- Current Android setup requires wake lock, typed media foreground service, and media-button receiver.

### Decision
Implement one `DhwaniAudioHandler` around `just_audio`, publish all state through `audio_service`, and apply `audio_session` music focus plus interruption/noisy-device handling.

### Why
It covers the required media lifecycle without duplicating platform responsibilities.

### Trade-offs
- Windows playback remains secondary to Android acceptance.
- Codec support ultimately depends on platform decoders.

### Revisit if
Android 16 media diagnostics reveal missing behavior or a critical plugin issue.

## DEC-0005 — Stream recording backend and licence

Date: 2026-08-16
Status: Accepted

### Question
How should Dhwani record network streams without microphone capture or lossy transcoding?

### Options considered
- Raw Dart byte capture only
- Retired FFmpegKit or a full GPL fork
- Maintained audio-only LGPL FFmpegKit fork with stream copy and FFprobe

### Research / evidence
- The original `arthenica/ffmpeg-kit` is archived and retired.
- `ffmpeg_kit_flutter_new_audio` 2.5.2 was published July 30, 2026, includes FFmpeg 8.1.2, supports Android API 24+, Windows, HTTPS and SAF, and states that the audio bundle contains no GPL components.

### Decision
Use `ffmpeg_kit_flutter_new_audio` 2.5.2. Record with `-c copy`, cancel only the owned session, and accept success only after file-size and FFprobe validation.

### Why
It supports direct streams and HLS, avoids re-encoding, is current, and avoids unnecessary GPL scope.

### Trade-offs
- Native binaries increase artifact size.
- Some broadcasters reject a second concurrent connection; the UI reports that honestly.

### Revisit if
16 KB verification fails, maintenance stops, or a shared-byte proxy becomes necessary.

## DEC-0006 — Catalogues and Darbhanga truth model

Date: 2026-08-16
Status: Accepted

### Question
How should global discovery coexist with a first-class Akashvani Darbhanga entry?

### Options considered
- Radio Browser only
- A bundled static list
- Radio Browser discovery plus Akashvani feed plus authoritative terrestrial overlay

### Research / evidence
- Radio Browser requires mirror discovery, randomized healthy selection, UUIDs, country codes, descriptive user agent, and failover.
- The current `codito/akashvani` feed includes Akashvani Darbhanga with Bihar and Maithili/Hindi metadata.
- Prasar Bharati lists Darbhanga at 1296 kHz.

### Decision
Merge Radio Browser and Akashvani records. Overlay verified Darbhanga metadata: 1296 kHz MW/AM, Darbhanga, Bihar, India, Maithili/Hindi. Treat stream URLs as refreshable data.

### Why
This gives global breadth and India-specific depth without confusing RF metadata with internet playback.

### Trade-offs
- The Akashvani feed is third-party discovery data.
- City inference must remain conservative.

### Revisit if
Prasar Bharati publishes a stable official catalogue API.

## DEC-0007 — Android compatibility and permissions

Date: 2026-08-16
Status: Accepted

### Question
Which Android baseline and permission posture fit Pixel 10?

### Options considered
- Target an older SDK
- Target API 37 preview
- Compile/target API 36, min API 24, edge-to-edge and least privilege

### Research / evidence
- Android 16 is API 36 and requires adaptive-layout testing.
- Android 15+ native dependencies require 16 KB page compatibility for modern devices and Play submissions.
- Media playback requires a typed foreground service; notifications require runtime permission on Android 13+.

### Decision
Compile/target API 36 with min API 24. Request internet, network state, wake lock, media foreground service, contextual notifications, and exact-alarm access only when a user enables an exact schedule. Never request microphone, location, or broad storage.

### Why
It matches the Pixel 10 generation and avoids unrelated personal-data access.

### Trade-offs
- Exact alarm and unattended work remain policy-controlled.
- Native libraries need explicit 16 KB verification.

### Revisit if
Play requirements change or a connected Pixel 10 reports newer behavior.

## DEC-0008 — Cleartext and scheduled actions

Date: 2026-08-16
Status: Accepted

### Question
Should Dhwani broadly allow HTTP streams and promise unattended schedules?

### Options considered
- Enable global cleartext and background launches
- Reject all HTTP and scheduling
- Prefer HTTPS, warn for custom HTTP, and use notification-driven schedules

### Research / evidence
- Android protects cleartext traffic while some legacy stations still use HTTP.
- Modern Android restricts foreground-service starts and exact alarms.

### Decision
Catalogues prefer HTTPS. User-added HTTP streams require an explicit warning. Schedules create exact notifications when allowed and otherwise inexact notifications; tapping opens the prepared action. The UI never guarantees unattended playback when Android cannot guarantee it.

### Why
This preserves legacy usefulness without overstating reliability.

### Trade-offs
- Arbitrary custom hosts cannot be allowlisted at build time.
- Scheduled actions may need one user tap.

### Revisit if
A compliant native foreground recording service is proven across target devices.

## DEC-0009 — Pin native splash tooling for installed Flutter

Date: 2026-08-16
Status: Accepted

### Question
Should Dhwani force `flutter_native_splash` 2.4.8 despite the installed Flutter test SDK's dependency pin?

### Options considered
- Override Flutter's pinned `meta` package
- Remove Flutter tests
- Use the newest compatible stable `flutter_native_splash` release

### Research / evidence
- Dependency solving proved that 2.4.8 requires `meta` 1.18+ while Flutter 3.41.9 pins `meta` 1.17.0 through `flutter_test`.
- Forcing the override or dropping tests would make the toolchain less reliable.

### Decision
Pin `flutter_native_splash` 2.4.7 until the installed Flutter stable line supports 2.4.8.

### Why
It preserves native splash generation and the complete test toolchain with no transitive override.

### Trade-offs
- One patch-level release behind current.

### Revisit if
Flutter is upgraded and dependency resolution accepts 2.4.8 or newer.

## DEC-0010 — Pin Riverpod to Dart 3.11-compatible stable

Date: 2026-08-16
Status: Accepted

### Question
Which Riverpod 3 release is compatible with the installed Dart 3.11.5 SDK?

### Options considered
- Force Riverpod 3.4.2
- Upgrade Flutter outside the project before building
- Pin the newest stable release whose declared SDK range includes Dart 3.11

### Research / evidence
- Pub.dev package metadata shows Riverpod 3.4.1+ requires Dart 3.12.
- Riverpod 3.3.2 requires Dart 3.7+ and was published June 10, 2026.

### Decision
Pin `flutter_riverpod` 3.3.2 for the installed Flutter 3.41.9 / Dart 3.11.5 toolchain.

### Why
It retains Riverpod 3 while respecting declared SDK compatibility and avoiding a disruptive global Flutter upgrade.

### Trade-offs
- Two patch/minor releases behind the registry head.

### Revisit if
The installed Flutter stable SDK moves to Dart 3.12+.

## DEC-0011 — Refresh Darbhanga from the official Akashvani live page

Date: 2026-08-17
Status: Accepted

### Question
How should Dhwani react after the third-party Darbhanga URL became stale?

### Options considered
- Keep the bundled URL
- Remove playback from the station
- Parse the current official Akashvani live page and retain the previous URL as a low-ranked fallback

### Research / evidence
- The discovery-feed BitGravity URL returned HTTP 404 during verification.
- `https://akashvani.gov.in/radio/live.php` currently publishes Darbhanga with a `radio.wavespb.com` HLS URL.
- The WAVES endpoint reset TLS from the German test network, showing why metadata and URL health must remain separate.

### Decision
Refresh Akashvani Darbhanga's stream URL from the official live page, merge it ahead of discovery-feed alternatives, apply bounded per-source startup timeouts, and preserve 1296 kHz independently as authoritative RF metadata.

### Why
This is fresher and more honest than either permanently trusting a copied URL or deleting a legitimate station when one stream fails.

### Trade-offs
- HTML parsing is less stable than an official catalogue API.
- Geo/network restrictions can still make an official stream unavailable.

### Revisit if
Prasar Bharati publishes a supported station catalogue/stream API.

## DEC-0012 — Disable Kotlin incremental compilation on this Windows cross-drive workspace

Date: 2026-08-17
Status: Accepted

### Question
How should the Android build handle Kotlin's invalid incremental cache roots across Flutter's C: runtime and the D: workspace?

### Options considered
- Move the user repository
- Delete caches before every build
- Disable Kotlin incremental compilation for this project

### Research / evidence
- Debug builds failed with cross-root incremental-cache path errors even after clean regeneration.
- Non-incremental in-process Kotlin compilation completed repeatedly on Java 21 and Gradle's configured toolchain.

### Decision
Set `kotlin.incremental=false` and `kotlin.compiler.execution.strategy=in-process` in `android/gradle.properties`.

### Why
It produces deterministic builds without moving or deleting user files.

### Trade-offs
- Kotlin rebuilds are slower.

### Revisit if
Flutter/Gradle fixes Windows cross-drive incremental cache normalization.

## DEC-0013 — Scheduled features use policy-aware reminders

Date: 2026-08-17
Status: Accepted

### Question
Can Dhwani reliably start arbitrary radio playback or recording unattended on current Android?

### Options considered
- Promise silent unattended starts
- Omit scheduling entirely
- Schedule visible, inexact-while-idle reminders that open a prepared station action

### Research / evidence
- Android restricts background foreground-service starts and exact alarms.
- `flutter_local_notifications` documents alarm/receiver setup and OEM delivery constraints.

### Decision
Implement one-time alarm and recording reminders with runtime notification permission and explicit copy that a user tap may be required. Do not label reminders as completed recordings.

### Why
It is useful, policy-compliant, and truthful across modern Pixel behavior.

### Trade-offs
- Repeating schedules and unattended capture are not guaranteed or claimed.

### Revisit if
A Play-policy-compliant foreground recording workflow is proven on physical target devices.

## DEC-0014 — Never block first frame on reminder initialization

Date: 2026-08-17
Status: Accepted

### Question
When should the reminders plug-in initialize?

### Options considered
- Await it before `runApp`
- Initialize only after the first reminder tap
- Start one idempotent future without awaiting it before the first Flutter frame

### Research / evidence
- A real cold install stayed on the native splash while notification initialization was awaited.
- Integration-test bindings did not reproduce the stall.
- Cold-start verification succeeded after moving initialization behind `runApp` while reminder methods await the same future.

### Decision
Start notification initialization asynchronously, cache the future, and await it inside every reminder operation.

### Why
Launch remains immediate without introducing notification races.

### Trade-offs
- A reminder tapped immediately after launch waits for initialization.

### Revisit if
The notification plug-in changes its initialization contract.

## DEC-0015 — Responsive first-run composition

Date: 2026-08-17
Status: Accepted

### Question
How should the editorial welcome screen adapt to landscape and large text?

### Options considered
- Shrink the hero typography
- Lock portrait orientation
- Preserve typography and switch to a scroll-safe two-column landscape composition

### Research / evidence
- Pixel-class landscape QA found a real 36-pixel bottom overflow.
- Portrait at 1.3× font scale remained legible.
- The two-column layout removed the overflow while retaining the supplied reference's large-type character.

### Decision
Use the original vertical composition in portrait and a constrained two-column, scroll-safe composition in landscape.

### Why
It preserves design quality and accessibility without orientation lock.

### Trade-offs
- The first-run screen has two intentional responsive compositions.

### Revisit if
Tablet or foldable testing identifies additional breakpoints.
