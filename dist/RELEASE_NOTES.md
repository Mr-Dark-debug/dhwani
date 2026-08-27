# Dhwani v1.4.1 - Reliable Sideload Playback

Dhwani 1.4.1 is a focused reliability release for phones that installed the APK outside the development device. It removes fresh-install permission and connectivity gates, sends stream requests directly through Android's native player, and repairs Akashvani Darbhanga discovery.

## Fixed for every install

- Radio starts without waiting for Android notification permission. Media-session playback does not require that permission; reminder notifications still ask contextually when scheduled.
- A transient `no connectivity` report can no longer prevent the player from trying a valid stream.
- Healthy audio is not interrupted by a brief connectivity handover event.
- Android ExoPlayer now sends request headers directly instead of using just_audio's localhost HTTP proxy.
- Existing 10-second per-source and 24-second whole-station bounds remain, so broken stations finish with a useful state instead of spinning forever.

## Akashvani Darbhanga

- Correctly decodes the public station feed when GitHub serves JSON as `text/plain` on Android.
- Restores the current official WAVES HLS URL published by Akashvani and tries it before older BitGravity fallbacks.
- Sends Akashvani Origin and Referer request context to the WAVES endpoint.
- Keeps the current release URL when Akashvani's live HTML page cannot be refreshed from a particular device/network.
- Preserves truthful `1296 kHz` MW/AM metadata independently of internet-stream availability.

## Verification

- Clean-install real Radio Swiss Jazz playback on the connected physical Pixel 10 reached PLAYING and paused successfully without notification permission.
- The physical-device Darbhanga probe attempted `radio.wavespb.com` first and the BitGravity fallback second, then terminated as unavailable on the current German network rather than hanging or crashing.
- Unit/widget suite, Flutter analyzer, release APK/AAB builds, manifest permissions, signer, checksums, and installed release behavior are release gates.

## Compatibility and limitations

- Version `1.4.1+7`; Android min SDK 24; compile/target SDK 36.
- Uses the existing protected signing lineage so installed Dhwani builds can upgrade in place.
- Darbhanga's broadcaster endpoints are externally operated and may remain geo/network dependent. Dhwani can select, refresh, and fail over sources, but cannot make an upstream broadcast available where its operator resets or removes it.
- The universal APK is large because it includes full FFmpeg protocol/codec support; the AAB supports ABI-specific store delivery.
