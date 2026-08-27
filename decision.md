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

## DEC-0016 — Evolve the local store for listening data and collections

Date: 2026-08-17
Status: Accepted

### Question
How should Dhwani persist favourite order, listening duration, stream health, and optional collections?

### Options considered
- Add more preference JSON blobs
- Replace Drift
- Migrate the existing Drift schema in place

### Research / evidence
- The existing structured store already owns stations, favourites, history, recordings, and reports.
- Drift supports versioned migrations and typed joins without discarding user data.

### Decision
Migrate schema version 1 to 2, add collection/member tables, and extend repository methods for favourite order, history metrics, and source outcomes.

### Why
Relational constraints and typed queries keep user data durable and backup-friendly without a second persistence system.

### Trade-offs
- Schema migrations now require explicit compatibility tests.

### Revisit if
Catalogue size or synchronization requirements outgrow on-device SQLite.

## DEC-0017 — Search cached data before remote data

Date: 2026-08-17
Status: Accepted

### Question
How should global search stay responsive and useful offline?

### Options considered
- Remote-only search
- Cache-only search
- Immediate cached results followed by a debounced remote merge

### Research / evidence
- Compact-device integration exposed unnecessary waiting and keyboard races in the remote-only flow.
- Cached Akashvani metadata answers semantic searches such as Maithili and 1296 without a network round trip.

### Decision
Render local ranked results immediately, debounce remote work, merge by station identity, and ignore stale request completions.

### Why
This produces fast offline behavior without giving up worldwide discovery.

### Trade-offs
- Results can expand after the initial render.

### Revisit if
The catalogue becomes large enough to justify SQLite full-text search.

## DEC-0018 — Persist and enforce behavioral settings

Date: 2026-08-17
Status: Accepted

### Question
Should settings be descriptive switches or active playback policies?

### Options considered
- Store UI state only
- Apply policies only after restart
- Apply and persist each policy through the owning service

### Research / evidence
- Wi-Fi-only, auto-reconnect, background playback, default scope, recording format, and autoplay all affect runtime behavior.

### Decision
Keep tiny preferences in `SharedPreferences`, push network policy into the audio handler, pause on background when disabled, restore sleep deadlines, and apply queue scope and recording format at the operation boundary.

### Why
A setting that does not change behavior is a broken feature.

### Trade-offs
- Lifecycle and network transitions require additional integration coverage.

### Revisit if
Settings need multi-device synchronization.

## DEC-0019 — Use device IANA time zones for repeated reminders

Date: 2026-08-17
Status: Accepted

### Question
How should weekday alarm and recording reminders survive daylight-saving changes?

### Options considered
- Schedule in UTC
- Infer a time zone from the numeric offset
- Read the platform IANA zone and use timezone-aware schedules

### Research / evidence
- `flutter_timezone` 5.1.0 is a current Apache-2.0 package that reports the platform time-zone identifier.
- `flutter_local_notifications` supports `dayOfWeekAndTime` matching with timezone locations.

### Decision
Initialize timezone data from the device IANA identifier and schedule one notification per selected weekday with inexact-while-idle delivery.

### Why
Wall-clock reminders remain stable across daylight-saving transitions without requesting exact-alarm privilege.

### Trade-offs
- OEM battery policy can still delay inexact delivery.

### Revisit if
A proven policy-compliant unattended recording service requires exact alarms.

## DEC-0020 — Offer Android equalization only where the audio session supports it

Date: 2026-08-17
Status: Accepted

### Question
Can Dhwani expose useful sound presets without destabilizing cross-platform playback?

### Options considered
- Hide equalization everywhere
- Add a third-party system-wide equalizer plug-in
- Use just_audio's session-scoped Android equalizer and hide it elsewhere

### Research / evidence
- just_audio 0.10.6 exposes `AndroidEqualizer` in its audio pipeline.
- Android's official `AudioEffect` API applies effects to a specific audio session.

### Decision
Provide Flat, Voice, Bass, Treble, and persistent custom band gains on Android only.

### Why
It uses the maintained playback dependency and avoids a dead control on unsupported platforms.

### Trade-offs
- Availability depends on the device audio-effect implementation.

### Revisit if
just_audio changes the API or other platforms gain an equivalent stable path.

## DEC-0021 — Bound wide-screen location content

Date: 2026-08-17
Status: Accepted

### Question
How should reference-inspired location lists render on a 2560×1600 tablet?

### Options considered
- Stretch every row edge to edge
- Create a separate tablet navigation rail
- Preserve the hierarchy and constrain reading width

### Research / evidence
- The API 36 Pixel Tablet profile passed navigation but produced excessively long 2464-pixel rows.

### Decision
Center location and station-list content in a 960 logical-pixel maximum while keeping the app bar full width.

### Why
It preserves the minimal reference language and touch behavior while improving scan distance on tablets.

### Trade-offs
- Large tablets retain intentional side whitespace.

### Revisit if
Dhwani adds a master-detail tablet browser.

## DEC-0022 — Replace the audio-only FFmpeg build with the LGPL full build

Date: 2026-08-17
Status: Accepted

Supersedes the recording-package portion of DEC-0006.

### Question
Which FFmpegKit variant actually records modern HTTPS radio streams while retaining stream copy, FFprobe, and optional audio conversion?

### Options considered
- Keep `ffmpeg_kit_flutter_new_audio`
- Downgrade stations to cleartext HTTP
- Use the HTTPS-only build and remove format conversion
- Use `ffmpeg_kit_flutter_new_full` without GPL components

### Research / evidence
- A fresh API 36 recording test proved that the audio-only native binary returned `https protocol not found` despite loading successfully.
- `ffmpeg_kit_flutter_new_full` 2.5.2 includes TLS and audio libraries, supports Android API 24+, Windows, FFprobe and SAF, and is LGPL-3.0 without GPL components.
- After replacement, a real Radio Swiss Jazz HTTPS stream produced a non-empty, FFprobe-recognized MP3 recording and the integration test deleted it cleanly.

### Decision
Use `ffmpeg_kit_flutter_new_full` 2.5.2, retain stream copy by default, and send a Dhwani user agent with bounded stream reconnect options.

### Why
Network recording must work with the HTTPS sources Dhwani intentionally prefers. The full non-GPL build is larger but is the smallest verified variant that preserves TLS plus requested conversion choices.

### Trade-offs
- Android artifacts are larger than the audio-only build.
- The dependency is LGPL-3.0 and requires the documented licence/redistribution obligations.

### Revisit if
A maintained smaller build combines TLS with the needed audio encoders and passes the same device recording test.

## DEC-0023 — Generation-controlled live playback state machine

Date: 2026-08-24
Status: Accepted

### Question
How should Dhwani prevent endless live-play Futures and stale station operations from corrupting state during rapid navigation?

### Options considered
- Add timeouts around the existing screen-level calls
- Serialize every command in an unbounded FIFO queue
- Make the audio handler authoritative, inject a testable engine, and let the newest generation supersede older tune/reconnect work

### Research / evidence
- The v1.1.0 handler awaited `AudioPlayer.play()`. just_audio's maintained example starts playback without awaiting broadcast completion, while source loading is awaited.
- just_audio 0.10.6 documents `PlayerInterruptedException` when a newer source load interrupts an older load.
- Current UI paths independently changed the selected provider, queue, history, and handler, and the handler changed `_index` before previous-session cleanup.

### Decision
Refactor the handler into an explicit state machine with an incrementing operation generation, per-source and whole-station deadlines, runtime error/processing subscriptions, bounded reconnect, atomic station transitions, and newest-intent-wins semantics. Introduce an injectable audio-engine boundary so cancellation, timeout, runtime error, and rapid input are deterministic unit tests.

### Why
Generation checks make late async results harmless without accumulating stale station connections. Awaiting preparation and confirmed PLAYING state, while starting the endless broadcast unawaited, gives UI callers a finite and truthful operation.

### Trade-offs
- This is a larger core refactor than patching individual screens.
- Media notification state must be emitted from the same explicit state machine rather than inferred opportunistically.

### Revisit if
just_audio exposes a first-class cancellable tune transaction with equivalent testability.

## DEC-0024 — One durable history row per confirmed listening session

Date: 2026-08-24
Status: Accepted

### Question
How should Recents avoid duplicate and failed zero-duration plays?

### Options considered
- Keep UI history inserts and deduplicate by timestamp
- Insert only after a session ends
- Start one row after actual playback begins and update that row on pause, stop, switch, or disposal

### Research / evidence
- v1.1.0 inserted history manually from location, search, discover, Saved, collections, and tuner flows while the audio handler separately inserted a duration row.
- The existing table already has an auto-increment row ID and duration column, so session semantics do not require a destructive schema migration.

### Decision
The audio authority alone starts a history row after PLAYING is confirmed and updates that row with measured duration when the session finishes. UI selection never writes history.

### Why
Failed loads are excluded, one listen is counted once, and an interrupted process can leave a valid partial zero-duration session without corrupting the database.

### Trade-offs
- Existing duplicate rows are preserved as historical user data; new duplication is prevented rather than guessing which old rows to delete.

### Revisit if
cross-device history synchronization later requires globally unique session IDs.

## DEC-0025 — Support directory HTTP streams with an explicit insecure-transport policy

Date: 2026-08-24
Status: Accepted

Supersedes the app-layer rejection portion of DEC-0014.

### Question
Should legitimate Radio Browser stations using plain HTTP remain unplayable even though Android is configured for dynamic cleartext radio hosts?

### Options considered
- Reject every directory HTTP URL
- Permit HTTP only for custom stations
- Prefer HTTPS, but permit token-free HTTP radio URLs from supported catalogue/custom sources and label transport security honestly

### Research / evidence
- v1.1.0 globally allowed Android cleartext for just_audio's header proxy but rejected non-custom HTTP in Dart, causing repeated directory incompatibility.
- Radio stations still commonly expose dynamic HTTP-only Icecast/Shoutcast endpoints; host enumeration in a static network-security configuration is not practical.

### Decision
Permit valid HTTP/HTTPS stream URLs, rank recent success then fewer failures then HTTPS, reject embedded credentials, and expose secure/insecure transport in diagnostics. Never send secrets or upgrade a URL synthetically.

### Why
This resolves the contradictory policy and maximizes legitimate radio compatibility without describing HTTP as secure.

### Trade-offs
- Cleartext audio can be observed or modified on the network.
- Android's cleartext permission remains broad because station hosts are discovered at runtime.

### Revisit if
Radio Browser reaches near-universal HTTPS coverage or Android adds a practical runtime host allow-list.

## DEC-0026 — Verified GitHub updater with legacy signing transparency

Date: 2026-08-24
Status: Accepted

### Question
How should self-update remain deterministic and safe when the published v1.1.0 APK is debug-signed?

### Options considered
- Keep the current first-APK downloader and hardcoded version
- Disable updating entirely
- Use installed package metadata, stable-release policy, deterministic assets, checksums and native APK inspection while preserving the published certificate for the immediate compatibility release

### Research / evidence
- Published v1.1.0 asset SHA-256 is `F024C9E517F6BD4882D6647F0531AB5C4AF46CC3AD20757096A7372049BC045D`.
- Its signer certificate SHA-256 is `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5` (`CN=Android Debug`). Android requires compatible signing identity for in-place updates.
- `package_info_plus` exposes installed version/build/package/signature metadata. Android `PackageManager.getPackageArchiveInfo` can inspect an APK before opening the installer.

### Decision
Build a typed update state/result API using actual installed metadata, stable-only automatic checks with cooldown, deterministic `Dhwani-vX-buildY-android.apk` selection, progress/cancel/retry/cleanup, SHA-256 verification, native package/version/signature inspection, and truthful `Installer opened` language. Keep the next compatibility artifact on the already-published signer only because no protected production key exists; document that a future production-key migration requires a one-time reinstall.

### Why
It prevents installing ambiguous, corrupt, wrong-package, downgraded, or differently signed APKs while accurately describing the unavoidable legacy certificate constraint.

### Trade-offs
- The published debug certificate is unsuitable as a long-term production identity.
- A secure new release key cannot replace it through an Android in-place upgrade.

### Revisit if
the owner supplies a protected production key or a store-managed signing migration becomes available.

## DEC-0027 — Hold Flutter 3.41.9 during the reliability refactor

Date: 2026-08-24
Status: Accepted

### Question
Should Dhwani upgrade from Flutter 3.41.9 to current stable 3.47.0 before fixing playback and updater architecture?

### Options considered
- Upgrade toolchain and dependencies immediately
- Never upgrade
- Complete the reliability state-machine baseline first, then evaluate the toolchain independently

### Research / evidence
- Flutter's official release index lists 3.47.0 as current stable.
- The 3.41.9 environment passes all 30 baseline tests and both Android builds; the current defects are application concurrency/state problems, not missing framework APIs.
- The baseline analyzer has two local unused-import warnings unrelated to Flutter version.

### Decision
Keep Flutter 3.41.9 for the core reliability change. Add only dependencies required for installed metadata and checksum validation. Re-evaluate 3.47.0 after deterministic regression and upgrade tests pass.

### Why
It avoids mixing a large framework migration with playback concurrency diagnosis and keeps causal evidence clear.

### Trade-offs
- Newer framework fixes are not adopted in the first reliability milestone.

### Revisit if
A verified bug fix needed by Dhwani exists only in Flutter 3.47.x or the completed suite passes before a dedicated migration trial.

## DEC-0028 — Prove recording liveness before showing REC

Date: 2026-08-24
Status: Accepted

### Question
When may Dhwani truthfully claim that a live network recording has started?

### Options considered
- Show REC as soon as FFmpeg is launched
- Wait for the process only
- Require the owned FFmpeg process to remain alive and the output to cross a non-trivial byte threshold within a bounded handshake

### Research / evidence
- The previous service entered `recording` immediately after asynchronous FFmpeg launch, even when the endpoint failed before producing media.
- On the API 36 x86_64 emulator, the full FFmpeg native process sometimes required more than ten seconds to initialize TLS and flush the first packets.
- A 25-second handshake reliably produced validated Radio Swiss Jazz MP3 and M4A files; FFprobe then supplied stored duration/format instead of wall-clock guesses.

### Decision
Expose explicit starting, recording, stopping, finalizing, saved, and failed states. Show REC only after the process is alive and at least 2048 bytes exist. Bound startup at 25 seconds, cancel owned processes on failure/switch, validate output with FFprobe, save valid partial captures, and delete invalid files.

### Why
The UI can no longer claim recording when zero media bytes exist, while slower native/TLS startup still has a realistic opportunity to succeed.

### Trade-offs
- Users may see Starting for several seconds on slower devices.
- Playback and recording remain independent network connections because tapping just_audio's internal bytes is not a supported public API.

### Revisit if
A maintained native byte-tee or local-proxy design can feed playback and recording from one connection without reducing protocol support.

## DEC-0029 — Paginate and health-rank Radio Browser mirrors

Date: 2026-08-24
Status: Accepted

### Question
How should large-country discovery avoid a hidden 500-station cap and single-mirror failures?

### Options considered
- Increase one fixed request limit
- Fetch every station eagerly
- Page in bounded batches, publish each cached page progressively, and rank mirrors by recent success/failure latency

### Research / evidence
- The prior country request used a fixed limit of 500.
- A deterministic 502-station test proves offset 0 and 500 are merged without losing results.
- The Radio Browser protocol provides multiple mirrors; public hosts can independently timeout or return malformed data.

### Decision
Fetch 500-station pages with cancellation, a 45-second total directory budget, a 10,000-result safety cap, deduplication, progressive cache callbacks, four-mirror failover, and temporary backoff based on observed failures/latency. Prune directory-only rows after 30 days while preserving favourites and custom data.

### Why
Users can browse cached/early results quickly and large countries are complete without allowing an upstream directory to consume unbounded memory, requests, or time.

### Trade-offs
- Counts above the safety cap are intentionally not loaded in one operation.
- Mirror health is local evidence, not a global uptime guarantee.

### Revisit if
Radio Browser introduces cursor pagination or a stable bulk-sync protocol.

## DEC-0030 — Reproducible GitHub releases retain the v1.1 signer lineage

Date: 2026-08-24
Status: Accepted

### Question
How can automated v1.2 releases remain installable over v1.1.0 without committing the legacy private key?

### Options considered
- Generate a new production key immediately and break in-place upgrade
- Commit or publish the old keystore
- Store the matching legacy keystore in encrypted GitHub Actions secrets, configure Gradle from ephemeral properties, and document the future one-time production-key migration

### Research / evidence
- Both published v1.1.0 and local upgrade tests use certificate SHA-256 `F11E976967911C8E585DD88817D6587076A802840699EEBF7E3C8304BEDBE3B5`.
- Android accepted v1.1.0 build 3 to v1.2.0 build 4 with the same signer and preserved `firstInstallTime` plus app data.
- GitHub authentication has repository/workflow scope, and the four signing inputs are now present as encrypted repository secrets.

### Decision
Use secret-backed Gradle signing in CI and retain the matching legacy signer for the v1.2 compatibility release. Pin Flutter 3.41.9 and Java 21 in the tag workflow; require format, analyze, tests, APK/AAB builds, deterministic names, and SHA-256 assets before publishing.

### Why
Existing installations can update in place, while private key bytes and passwords never enter the repository or workflow logs.

### Trade-offs
- The certificate is still an Android debug identity and is unsuitable as the permanent Play signing lineage.
- Migrating to a dedicated production key later requires a clearly communicated reinstall unless a store-managed migration is available.

### Revisit if
A dedicated release identity and distribution-channel migration plan are ready.

## DEC-0031 — Use an in-process broken-radio server for decoder integration

Date: 2026-08-24
Status: Accepted

### Question
How should transport failures be reproduced without waiting for random public stations to fail?

### Options considered
- Depend only on live internet smoke tests
- Mock the entire audio engine
- Keep fast fake-engine state tests and add an Android integration fixture served from the app process

### Research / evidence
- Fake-engine tests deterministically cover hanging Futures and operation ordering but cannot validate ExoPlayer redirect/HTTP behavior.
- An Android loopback HttpServer successfully served a generated WAV, delayed headers, redirects, 404/500 responses, and connection-drop endpoints without external network dependency.

### Decision
Retain both test layers: injected-engine unit tests for exhaustive state transitions and a controlled Android server test for platform-decoder redirect, terminal failure, and stale-intent cancellation. Keep a separate real Radio Swiss Jazz smoke test.

### Why
Together they distinguish app state-machine correctness, platform integration, and real-world internet health rather than conflating them.

### Trade-offs
- Integration builds remain slow because the full FFmpeg native dependency is packaged.

### Revisit if
Flutter gains an official lightweight media integration-test harness with equivalent decoder coverage.

## DEC-0032 — Keep release automation on supported Node 24 actions

Date: 2026-08-24
Status: Accepted

### Question
How should the release workflow respond to GitHub's Node 20 action deprecation annotations?

### Options considered
- Ignore the warnings because v1.2.0 published successfully
- Keep deprecated action majors until they fail
- Move GitHub-owned actions to their supported Node 24 majors and use the authenticated GitHub CLI for idempotent release publication

### Research / evidence
- The successful v1.2.0 job warned that checkout v4, setup-java v4, upload-artifact v4, and the third-party release action were being forced from deprecated Node 20 to Node 24.
- Official GitHub repositories document checkout v6, setup-java v5, and upload-artifact v6 on Node 24 for current hosted runners.
- `gh release create/edit/upload --clobber` is already authenticated by the job token and avoids an additional third-party JavaScript action for publication.

### Decision
Use `actions/checkout@v6`, `actions/setup-java@v5`, and `actions/upload-artifact@v6`. Publish idempotently with the preinstalled GitHub CLI and `github.token`.

### Why
Future tag builds avoid a known runtime deprecation and keep the externally mutating release step small, reviewable, and first-party authenticated.

### Trade-offs
- These action majors require a current GitHub runner; Dhwani uses GitHub-hosted `ubuntu-latest`, which satisfies that requirement.

### Revisit if
GitHub changes hosted-runner compatibility or offers a first-party dedicated release-upload action.

## DEC-0033 — Playback requests outrank permission and connectivity hints

Date: 2026-08-27
Status: Accepted

### Question
How should Dhwani behave when a fresh sideload has no notification grant or Android briefly reports no connectivity?

### Options considered
- Require every declared permission before attempting audio
- Trust connectivity plug-in state and reject playback when it reports `none`
- Start user-requested media immediately, keep reminder permission contextual, and let the real player request classify reachability

### Research / evidence
- `INTERNET` and `ACCESS_NETWORK_STATE` are install-time normal permissions.
- Android media-session notifications are exempt from the Android 13 notification runtime permission.
- A clean physical Pixel 10 probe reported connectivity `none` while Android simultaneously showed validated Wi-Fi, proving the status can be transient.
- `just_audio` supports direct Android ExoPlayer headers, avoiding the default localhost proxy used when request headers are present.

### Decision
Never await notification permission before play, tune, or retry. Treat connectivity as advisory except for the explicit user-selected Wi-Fi-only policy. Send headers natively through ExoPlayer, and let bounded stream attempts determine playing, offline, unavailable, geo-blocked, or unsupported state.

### Why
This removes three device-dependent gates from the user's Play action without adding permissions or weakening failure bounds.

### Trade-offs
- A truly offline attempt can take the source budget to fail instead of being rejected instantly.
- Reminder notifications still need a contextual runtime prompt on Android 13+.

### Revisit if
Android introduces a reliable validated-network callback that is guaranteed not to race app startup, or media notification exemption rules change.
