# Dhwani v1.4.2 - Akashvani Darbhanga Delivery Fix

Dhwani 1.4.2 is a deliberately narrow follow-up for Akashvani Darbhanga. It preserves every other station's connection behavior.

## Akashvani Darbhanga

- Tries the broadcaster's CloudFront delivery host before its public WAVES hostname, which some ISP/content filters reset.
- Keeps the current official WAVES stream as the second source and the older BitGravity sources as bounded fallbacks.
- Inserts the delivery URL into the offline seed and cached-catalogue merge, preventing an older installation's stale station record from taking priority.
- Preserves the station's truthful `1296 kHz` MW/AM metadata independently of internet-stream availability.

## Other stations are unchanged

- The new fallback is conditional on the Akashvani Darbhanga station identity only.
- A regression test proves another country's station retains the same primary and backup URL order.
- Radio Swiss Jazz reached PLAYING and paused on an Android Pixel 10-equivalent emulator after this change.

## Verification and limitation

- Flutter analyzer passed with no issues; all 66 unit/widget tests passed.
- The Android Darbhanga probe confirmed the order CloudFront -> WAVES -> legacy BitGravity and a bounded unavailable result instead of a hang.
- At the overnight test time in India, the broadcaster's delivery host returned HTTP 404 and its WAVES hostname was reset on the current network. Dhwani cannot create audio while the broadcaster is off-air; the new direct delivery source is available for its live transmission window.

## Compatibility

- Version `1.4.2+8`; Android min SDK 24; compile/target SDK 36.
- Uses the existing protected signing lineage for in-place upgrades.
- The universal APK is large because it includes full FFmpeg protocol/codec support; the AAB supports ABI-specific store delivery.
