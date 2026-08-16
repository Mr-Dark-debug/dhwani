# Dhwani 1.0.0 Preview 1

This Android preview contains the complete verified Dhwani implementation in this repository: live station discovery/search, Akashvani Darbhanga metadata and failover, background media controls, favourites/history/custom stations, network-stream recording, recording playback/share/SAF export, sleep timer, Car Mode, backup, dark mode, and Android policy-aware reminders.

## Verification

- Android 16/API 36 Pixel-class emulator
- 13 unit/widget tests passed
- 2 Android integration flows passed
- Radio Swiss Jazz live playback, ICY metadata, background media session, notification pause/resume, 26-second recording, recording playback, and Downloads export verified
- APK installed and cold-started
- 16 KB APK alignment verified

## Important preview limitations

- The APK and AAB are locally signed with the Android debug certificate because a private owner-controlled release keystore was not supplied. The APK is installable, but these artifacts must not be used as the permanent Play signing lineage.
- Akashvani Darbhanga's current official stream reset TLS from the German test network; its previous CDN URL returned 404. Dhwani reports this honestly and the 1296 kHz metadata remains correct.
- Physical Pixel 10, Bluetooth hardware, and audible speaker output were not available; API 36 emulator diagnostics were used.
- Scheduled alarm/recording features are policy-aware reminders, not guaranteed unattended Android background launches.

Verify downloads with `SHA256SUMS.txt`.
