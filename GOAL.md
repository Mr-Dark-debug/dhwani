# Dhwani Surgical Reliability Goal

This release has exactly two product goals:

1. Make automatic GitHub update detection reliable at application cold start and resume, with separate successful and failed cooldowns, retained update-available state, strict stable-version parsing, and manual checks that always bypass automatic cooldowns.
2. Make Akashvani Darbhanga as reliable as technically possible by dynamically discovering current official stream candidates, retaining a bounded last-known-good candidate, refreshing once after stale-source failure, and reporting the broadcaster as currently off air when it is not publishing a valid HLS stream.

## Non-goals

- No redesign or theme changes.
- No general player architecture refactor.
- No recording, navigation, retro tuner, Radio Browser, other-country, or other-station behavior changes.
- No dependency upgrades unless one is strictly required for these two goals.
- No weakening of APK checksum, package-name, version-code, or signing-certificate verification.

## Release gate

The work is complete only after deterministic updater and Darbhanga resolver tests, full regression tests, Android integration checks, release builds, protected GitHub CI, published asset/checksum verification, and downloaded-APK inspection/install all pass. A real Darbhanga PLAYING result may be reported only if media segments actually flow during an active broadcaster window; an off-air broadcaster must be reported honestly.
