# Dhwani v1.4.4 - Bihar-wide Akashvani refresh

Dhwani 1.4.4 extends the v1.4.3 Darbhanga resolver to every Akashvani station. It changes only stream-source resolution and failure messaging; the existing player, recording, navigation, tuner, theme, and signing lineage remain intact.

## Why this release

- The discovery feed still serves retired BitGravity `pbaudio*` URLs (HTTP 404) for Bihar stations, and only Darbhanga had an in-app resolver. Patna, Bhagalpur, Purnia, Rainbow/VBS Patna therefore had no working candidate on any network.
- Dhwani now refreshes all Akashvani stations from the official live page in one bounded, cached fetch and prepends the official URL ahead of stale feed URLs. Darbhanga keeps its HLS-validated resolution.
- The official-page parser ignores retired `//live_url:` comment entries, and the retired CloudFront mirror (verified HTTP 404) is no longer tried.
- Offline/first-run seeds carry the current WAVES URLs for all seven Bihar stations.

## Verification and current live boundary

- `flutter analyze`: no issues; `flutter test`: 103 passed.
- Live re-verification on 2026-10-01 confirmed the official page, the 404 feed URLs, and the 404 CloudFront mirror. On the filtered test network `radio.wavespb.com` is content-filtered (Meraki block page over HTTP, TLS reset over HTTPS) while BitGravity push hosts return 200. TLS/reset failures now suggest retrying on mobile data. Audible Darbhanga playback on an unfiltered network is not claimed from this test window.

## Compatibility

- Version `1.4.4+10`; Android min SDK 24; compile/target SDK 36.
- Uses the existing protected signing lineage for in-place upgrades.
