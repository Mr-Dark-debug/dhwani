# Dhwani v1.4.3 - Darbhanga & Update Detection

Dhwani 1.4.3 is a surgical reliability release. It changes only automatic update discovery and Akashvani Darbhanga source recovery; the existing player, recording, navigation, tuner, theme, other countries, and other stations remain intact.

## Reliable automatic updates

- Checks start asynchronously after the app's first rendered frame and when Dhwani resumes.
- A successful GitHub lookup is cached for one hour. A network/parsing failure retries after ten minutes and never writes the successful-check timestamp.
- Manual **Check for updates** always contacts GitHub, regardless of automatic cooldowns.
- Simultaneous checks share one request. A detected release remains visible in Settings and its update sheet appears once per release during the process session.
- Stable `vX.Y.Z` releases compare semantic version and Android build number, and neither identity may move backward. Beta and RC tags are excluded.
- APK SHA-256, package name, version code, signer, and trusted GitHub asset validation are unchanged.

## Akashvani Darbhanga

- Dhwani reads the official Akashvani page's structured channel `69` object instead of scanning an arbitrary nearby text window.
- The official `live_url` is validated as HLS with a small bounded GET; redirects and changing delivery CDN hosts are learned dynamically.
- Candidate order is fresh official source, last-known-good, redirect-derived delivery source, station feed, then static emergency fallbacks, with duplicates removed.
- A successfully played source is remembered for seven days. Three consecutive failures invalidate it; any failed candidate sequence triggers at most one fresh official lookup.
- HTTP 404/410 from the broadcaster's current official manifest is shown as **Akashvani Darbhanga is currently off air**, while DNS, TLS, timeout, network filtering, and discovery failures retain their own truthful failure paths.
- `1296 kHz · Darbhanga, Bihar` remains RF metadata; Dhwani does not claim the phone receives AM directly.

## Verification and current live boundary

- `flutter analyze`: no issues; `flutter test`: 99 passed.
- Android ExoPlayer reached PLAYING for Radio Swiss Jazz, Deutschlandfunk, and Akashvani Live News 24x7. Next, Previous, Play/Pause, Recents, and real recording passed.
- During the 04:33 IST Darbhanga probe, the official WAVES connection was reset on the German route and old BitGravity/CloudFront endpoints did not provide media. Dhwani stopped cleanly and did not claim LIVE. An active-broadcast audio success is therefore not claimed for this test window.

## Compatibility

- Version `1.4.3+9`; Android min SDK 24; compile/target SDK 36.
- Uses the existing protected signing lineage for in-place upgrades.
