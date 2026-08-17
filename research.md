# Dhwani Research Log

Important dependency and platform research is recorded here with dated primary sources and implementation consequences.

## 2026-08-16 — Research baseline

The repository was empty at project start. Package versions, Android target requirements, Radio Browser discovery, Akashvani sources, media playback, recording, storage/export, alarms, and launcher/splash tooling will be verified against current official documentation before selection.

## 2026-08-16 — Application foundations

| Package | Version | Source / health | Decision |
| --- | ---: | --- | --- |
| `flutter_riverpod` | 3.4.2 | pub.dev; published 2026-07-28; MIT | State and dependency injection. |
| `go_router` | 17.5.0 | pub.dev API; 2026-08-10; Flutter team; BSD-3 | Declarative routes. |
| `dio` | 5.11.0 | pub.dev API; 2026-07-25; MIT | Timeouts, cancellation, streaming, typed failures. |
| `drift` / `drift_flutter` | 2.34.3 / 0.3.1 | active repository; MIT | Structured SQLite; EOL `sqlite3_flutter_libs` rejected. |
| `shared_preferences` | 2.5.5 | Flutter team; BSD-3 | Small settings only. |

## 2026-08-16 — Playback and media session

- `just_audio` 0.10.6, `audio_service` 0.18.19, and `audio_session` 0.2.4 were published 2026-06-29 by the established Ryan Heise package family.
- `audio_service` officially covers background playback, notifications, lock-screen/headset controls, queue navigation, artwork, and Android Auto media browsing.
- Current Android setup requires wake lock, foreground-service, media-playback foreground-service, a media service, and media-button receiver.
- Selected with MIT licences.

## 2026-08-16 — Radio Browser

- Official docs: https://api.radio-browser.info/ and https://docs.radio-browser.info/
- Clients discover mirrors through DNS/SRV or `/json/servers`, health-rank and fail over, send a speaking user agent, use UUID fields and standardized country codes, and register actual station clicks.
- Dhwani uses HTTPS, bounded timeouts, cached mirrors, conservative retries, and click registration only when playback is requested.

## 2026-08-16 — Akashvani Darbhanga

- Discovery feed: https://raw.githubusercontent.com/codito/akashvani/master/stations.json
- Current schema: `name`, `stream_url`, `state`, `language`, `epg_url`, `epg_id`.
- Current entry: Akashvani Darbhanga, Bihar, Maithili/Hindi, HTTPS HLS ending `pbaudio160/playlist.m3u8`, EPG id 69.
- Prasar Bharati's East Zone service document lists Darbhanga at 1296 kHz.
- The feed is refreshable discovery data; the app does not claim the URL is permanent or the RF frequency itself is internet-playable.

## 2026-08-16 — Recording

- Original `arthenica/ffmpeg-kit`: rejected because it is archived and retired.
- Full `ffmpeg_kit_flutter_new`: rejected because it adds unnecessary GPL video components.
- `ffmpeg_kit_flutter_new_audio` 2.5.2: chosen. Published 2026-07-30; FFmpeg 8.1.2; Android API 24+; Android/iOS/Linux/macOS/Windows; HTTPS, SAF and FFprobe; no GPL components per package documentation; LGPL-3.0.
- Dhwani uses stream copy/remux and FFprobe validation. It never requests microphone permission.

## 2026-08-16 — Android 16, scheduling, and storage

- Android 16/API 36 requires adaptive layouts; target-36 orientation restrictions are ignored on large screens.
- Android's 16 KB page guidance requires compatible native dependencies on Android 15+ devices and Play submissions.
- `file_selector` 1.1.0 can open files on Android but cannot select a save location there, so Android export uses the Storage Access Framework.
- `flutter_local_notifications` 22.3.0 requires Flutter 3.38.1+, Java 17, desugaring, and manifest receivers. It documents OEM/background schedule restrictions; Dhwani presents them honestly.

## 2026-08-16 — Branding tooling

- `flutter_launcher_icons` 0.14.4 is the current stable fluttercommunity.dev release.
- `flutter_native_splash` 2.4.8 was published 2026-05-29 and supports Android 12+ and dark mode.
- The logo concept was generated with the built-in image-generation tool from a transparent near-black/warm-red tuner-and-wave brief. Project derivatives are under `assets/branding/`.
- `flutter_native_splash` 2.4.8 was incompatible with Flutter 3.41.9's `meta` 1.17 test pin; 2.4.7 is the newest compatible stable selection. No dependency override was used.
- `flutter_riverpod` 3.4.1+ requires Dart 3.12; the installed Dart is 3.11.5, so 3.3.2 is the newest compatible stable release.
- `drift_dev` 2.34.1+ requires an analyzer line that needs `meta` 1.18; Flutter 3.41.9 pins 1.17. Runtime Drift remains 2.34.3 and generator 2.34.0 is pinned as the compatible pair.

## 2026-08-17 — Live source and device verification

- Official Akashvani page inspected: `https://akashvani.gov.in/radio/live.php`.
- Current Darbhanga HLS discovered dynamically: `https://radio.wavespb.com/live/8e074285599ed45d/8e074285599ed45d.m3u8`.
- Result from the German test network: TLS connection reset. The previous `air.pc.cdn.bitgravity.com/.../pbaudio160/playlist.m3u8` source returned HTTP 404. Both failures are upstream/network evidence, not converted into a false LIVE state.
- Independent public playback smoke source: Radio Swiss Jazz, `https://stream.srg-ssr.ch/m/rsj/mp3_128`. Android reached PLAYING, received ICY track metadata, populated a media session, and continued in the background.
- `ffmpeg_kit_flutter_new_audio` successfully loaded its x86_64 library on API 36, recorded 485,262 bytes of MP3 audio, and the resulting file was playable and exportable through Android SAF.
- `connectivity_plus` 7.3.1 reports a list of network types; Dhwani treats it as policy context only. Actual request/audio errors remain source of truth.
- `cupertino_icons` 1.0.9 was added because release tree-shaking found a Cupertino icon reference in the dependency graph; this removed the missing font-asset warning without disabling tree shaking.

## 2026-08-17 — Competitive interaction review

TuneIn, Simple Radio, myTuner, Radio Garden, and Radioplayer were reviewed at a product-pattern level. Useful common patterns retained in an original interface: persistent mini-player, immediate connection feedback, notification controls, location/language discovery, recents, favourites, sleep timing, and simple car controls. Dhwani deliberately keeps its own editorial tuner/frequency hero and does not copy any competitor screen.

## 2026-08-17 — Behavioral close-out research

- Android foreground-service start restrictions: https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start
- Android alarm guidance and exact-alarm privilege: https://developer.android.com/develop/background-work/services/alarms
- Android 15 foreground-service changes: https://developer.android.com/about/versions/15/changes/foreground-service-types
- `flutter_timezone` 5.1.0: Apache-2.0 and multi-platform; selected for the device IANA identifier used by repeated reminder schedules.
- just_audio 0.10.6 documents `AndroidEqualizer`; Android's official `AudioEffect` API confirms effects attach to a player audio session. Dhwani exposes equalization only on Android.
- Dio 5.9.2's public `HttpClientAdapter` contract supports deterministic mirror-failure and malformed-response tests without real network dependence.
- A dedicated Android notification status icon is derived from Dhwani's monochrome adaptive-icon mark; the colored launcher icon is no longer used as a small notification glyph.
- Recording backend correction: API 36 testing proved `ffmpeg_kit_flutter_new_audio` 2.5.2 was compiled without HTTPS protocol support. It was rejected and replaced by `ffmpeg_kit_flutter_new_full` 2.5.2, whose current pub.dev metadata identifies FFmpeg 8.1.2, Android API 24+, Android/iOS/Linux/macOS/Windows support, no GPL components, and LGPL-3.0 licensing. A real HTTPS MP3 recording passed after the replacement.
