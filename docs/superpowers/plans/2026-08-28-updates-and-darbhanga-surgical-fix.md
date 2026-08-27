# Update Detection and Darbhanga Surgical Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reliably detect stable GitHub releases from the application lifecycle and dynamically recover Akashvani Darbhanga stream changes without changing any other station or working product area.

**Architecture:** Keep APK download, checksum, package, version-code, signer, and installer behavior in `AppUpdateService`; move cadence/session presentation into a root-owned Riverpod coordinator. Replace the brittle Darbhanga HTML window scan with a dedicated resolver keyed by official channel `69`, using bounded HLS GET/redirect validation and SharedPreferences last-known-good state. Inject only a narrow candidate-refresh callback into the existing player so other stations use the exact current path.

**Tech Stack:** Flutter 3.41.9, Dart 3.11.5, Riverpod 3.3.2, Dio 5.11, SharedPreferences, package_info_plus, just_audio, flutter_test, integration_test.

## Global Constraints

- Do not redesign, refactor the general player, change recording/navigation/theme/tuner, or change other stations/countries.
- Keep `Mr-Dark-debug/dhwani`, SHA-256, package identity, version-code, and signer validation unchanged.
- Automatic success cooldown is 1 hour; automatic failure retry cooldown is 10 minutes; manual checks bypass both.
- Darbhanga remains `1296 kHz` MW/AM metadata and is never represented as phone RF reception.
- Darbhanga discovery and one forced refresh must remain bounded by the existing whole-station startup deadline.
- Static WAVES/CloudFront/BitGravity URLs are last-resort candidates, not the discovery architecture.
- Release only after formatting, analysis, all tests, Android checks, protected CI, and downloaded public artifact verification pass.

---

### Task 1: Pure Stable GitHub Release Lookup

**Files:**
- Modify: `lib/core/updater/app_update_service.dart`
- Modify: `test/app_update_service_test.dart`

**Interfaces:**
- Consumes: `AppIdentity(version, buildNumber)` from package_info_plus.
- Produces: `Future<UpdateCheckResult> checkForUpdate()` with no automatic cooldown side effect; strict `vMAJOR.MINOR.PATCH`; lexicographic semantic-version then build comparison.

- [ ] **Step 1: Add failing comparison/parsing tests.**

```dart
expect(await lookup(local: '1.4.2', build: 8, remote: '1.4.3', remoteBuild: 9), isA<UpdateAvailable>());
expect(await lookup(local: '1.4.2', build: 8, remote: '1.4.2', remoteBuild: 9), isA<UpdateAvailable>());
expect(await lookup(local: '1.4.3', build: 9, remote: '1.4.3', remoteBuild: 9), isA<UpdateUpToDate>());
expect(await lookup(local: '1.4.3', build: 10, remote: '1.4.3', remoteBuild: 9), isA<UpdateUpToDate>());
expect(await lookup(local: '1.4.2', build: 8, remote: '1.4.3-beta', remoteBuild: 9), isA<UpdateCheckFailed>());
expect(await lookup(local: '1.4.2', build: 8, remote: '1.4.3-rc1', remoteBuild: 9), isA<UpdateCheckFailed>());
```

- [ ] **Step 2: Verify the new tests fail against prefix parsing.**

Run: `flutter test test/app_update_service_test.dart`
Expected: prerelease suffix cases fail because the current regex accepts prefixes.

- [ ] **Step 3: Make the lookup pure and parsing strict.**

```dart
static final RegExp _stableRelease = RegExp(r'^[vV]?(\d+)\.(\d+)\.(\d+)$');

static int compareReleaseIdentity({
  required String remoteVersion,
  required int remoteBuild,
  required String installedVersion,
  required int installedBuild,
}) {
  final versionComparison = compareSemantic(remoteVersion, installedVersion);
  if (versionComparison != 0) return versionComparison;
  return remoteBuild.compareTo(installedBuild);
}
```

Remove `updateLastAutomaticCheck`, `automaticCheckCooldown`, and `manual` cadence handling from this network/download service. Log installed identity, parsed remote identity, no-update, available, network failure, and parsing failure without URLs containing query strings.

- [ ] **Step 4: Run updater service tests.**

Run: `flutter test test/app_update_service_test.dart`
Expected: all service tests pass and download/signature/install tests remain unchanged.

### Task 2: Root-Owned Update Coordinator

**Files:**
- Create: `lib/core/updater/app_update_coordinator.dart`
- Modify: `lib/app/providers.dart`
- Modify: `lib/app/app.dart`
- Modify: `lib/app/router.dart`
- Modify: `lib/features/player/player_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Create: `test/app_update_coordinator_test.dart`
- Modify: `test/feature_widget_test.dart`

**Interfaces:**
- Consumes: `AppUpdateService`, `SharedPreferences`, injectable `DateTime Function()`.
- Produces: `UpdateCoordinatorState`, `checkAutomatically(UpdateTrigger)`, `checkManually()`, `markPresented(tag)`.

- [ ] **Step 1: Add deterministic coordinator tests for cold start, resume, separate timestamps, failure retry, success cooldown, manual bypass, in-flight deduplication, and once-per-release/session presentation.**

```dart
expect(await coordinator.checkAutomatically(UpdateTrigger.coldStart), isA<UpdateAvailable>());
expect(preferences.getString(UpdateCoordinator.lastSuccessfulCheckKey), isNotNull);
expect(preferences.getString(UpdateCoordinator.lastFailedCheckKey), isNull);
expect(coordinator.takePresentation('v1.4.3'), isTrue);
expect(coordinator.takePresentation('v1.4.3'), isFalse);
```

Use fake lookup results for 403, 429, timeout, parse failure, and success. Advance an injected clock by 9 and 10 minutes for failure retry and by 59 and 60 minutes for success cooldown.

- [ ] **Step 2: Verify coordinator tests fail because the coordinator does not exist.**

Run: `flutter test test/app_update_coordinator_test.dart`
Expected: compile failure for missing coordinator types.

- [ ] **Step 3: Implement coordinator state and cadence.**

```dart
enum UpdateTrigger { coldStart, resume, manual }

class UpdateCoordinatorState {
  const UpdateCoordinatorState({this.checking = false, this.available, this.lastResult});
  final bool checking;
  final AppReleaseInfo? available;
  final UpdateCheckResult? lastResult;
}
```

The coordinator must store `lastSuccessfulUpdateCheck` only for a parsed `UpdateAvailable` or `UpdateUpToDate`, store `lastFailedUpdateCheck` for `UpdateCheckFailed`, keep one `_inFlight` Future, retain `available`, and keep an in-memory set of presented tags. Automatic exceptions are converted to failure state and never escape root lifecycle calls.

- [ ] **Step 4: Move lifecycle ownership to `DhwaniApp`.**

Add a root navigator key to `GoRouter`, schedule `checkAutomatically(coldStart)` with `WidgetsBinding.instance.addPostFrameCallback`, call `checkAutomatically(resume)` on `AppLifecycleState.resumed`, and show `AppUpdateSheet` through the navigator context only when `takePresentation(tag)` returns true.

- [ ] **Step 5: Remove the PlayerScreen automatic side effect and connect Settings to coordinator state/manual bypass.**

Settings subtitle must render `Update available · vX.Y.Z` when retained state contains a release. Manual tap calls `checkManually()` regardless of timestamps and uses the existing update sheet/download verifier.

- [ ] **Step 6: Run coordinator and widget acceptance tests.**

Run: `flutter test test/app_update_coordinator_test.dart test/feature_widget_test.dart`
Expected: cold start/resume/manual/session-presentation/UI state tests pass.

### Task 3: Structured Darbhanga Discovery and Last-Known-Good State

**Files:**
- Create: `lib/data/datasources/akashvani_darbhanga_resolver.dart`
- Modify: `lib/data/datasources/akashvani_api.dart`
- Modify: `lib/data/repositories/catalogue_repository.dart`
- Create: `test/akashvani_darbhanga_resolver_test.dart`
- Modify: `test/akashvani_api_test.dart`
- Modify: `test/catalogue_repository_test.dart`

**Interfaces:**
- Consumes: official HTML `channels['69']`, current feed candidate, SharedPreferences cache, bounded Dio GET.
- Produces: `Future<DarbhangaResolution> resolve({required RadioStation station, bool forceRefresh = false})`; `recordPlaybackResult(url, success, failureReason)`.

- [ ] **Step 1: Add the 18 deterministic resolver cases from GOAL.md.**

Test fixtures must include reordered channel properties, more than 1000 characters between unrelated stations, redirect chains with two different CloudFront hosts, valid master/media playlists, 404/403/timeout/DNS/TLS/reset, unavailable official page, duplicates, stale feed, and a request counter proving at most one refresh.

- [ ] **Step 2: Verify resolver tests fail because the resolver does not exist.**

Run: `flutter test test/akashvani_darbhanga_resolver_test.dart`
Expected: compile failure for missing resolver types.

- [ ] **Step 3: Parse the server-rendered channel map structurally by canonical channel `69`.**

```dart
static const channelId = '69';
static const epgId = '333';

final objectBody = extractBalancedObjectAfterKey(html, "'$channelId'");
final name = extractJsString(objectBody, 'name');
final liveUrl = extractJsString(objectBody, 'live_url');
if (name != 'Akashvani Darbhanga') throw const FormatException('Channel 69 identity changed');
```

Do not use a fixed character window. Treat `8e074285599ed45d` as mutable URL content, never as canonical station identity.

- [ ] **Step 4: Implement bounded redirect/HLS validation.**

Use GET with `Accept: application/vnd.apple.mpegurl, application/x-mpegURL, */*`, official page Referer, normal Dhwani User-Agent, `followRedirects: false`, maximum five redirects, per-request timeouts, and a `Range: bytes=0-65535` hint. Accept only bodies containing `#EXTM3U` plus either `#EXT-X-STREAM-INF` or `#EXTINF` and a non-comment playlist/segment line. Capture each HTTPS redirect target as a delivery candidate; never persist cookies or signed query strings in logs.

- [ ] **Step 5: Implement candidate order, TTL, failure invalidation, and deduplication.**

Order fresh validated official URL, recently successful cached URL, fresh redirect-derived delivery URL, current feed URL, then static emergency URLs. Persist URL, discovery source, discovered-at, last-success, and consecutive failures. Clear/promote the cached URL after three consecutive playback failures; never loop discovery.

- [ ] **Step 6: Restrict catalogue mutation to Darbhanga and prove other stations are unchanged.**

`AkashvaniApi` delegates Darbhanga only; `CatalogueRepository` keeps exact stream order for all non-Darbhanga input. Static WAVES/CloudFront/BitGravity entries move to resolver emergency candidates.

- [ ] **Step 7: Run resolver/catalogue tests.**

Run: `flutter test test/akashvani_darbhanga_resolver_test.dart test/akashvani_api_test.dart test/catalogue_repository_test.dart`
Expected: all matrix tests pass, including exact non-Darbhanga list equality.

### Task 4: One Bounded Darbhanga Refresh and Honest Off-Air State

**Files:**
- Modify: `lib/core/audio/dhwani_audio_handler.dart`
- Modify: `lib/core/audio/playback_failure.dart`
- Modify: `lib/app/providers.dart`
- Modify: `lib/main.dart`
- Modify: `lib/features/player/player_screen.dart`
- Modify: `test/audio_handler_test.dart`
- Modify: `integration_test/darbhanga_live_probe_test.dart`

**Interfaces:**
- Consumes: optional Darbhanga-only resolver callback and playback-result observer.
- Produces: original handler behavior for other stations; initial Darbhanga resolution; exactly one forced refresh after stale candidate failure; `offAir` failure/status.

- [ ] **Step 1: Add handler tests showing another station never invokes resolution and Darbhanga refreshes once within the same station deadline.**

Use the existing fake audio engine. Assert old candidate 404 -> refreshed candidate plays, all 404 -> off-air, and callback invocation count never exceeds two (initial plus one forced refresh).

- [ ] **Step 2: Add narrow optional callbacks without restructuring the state machine.**

```dart
typedef StationCandidateResolver = Future<StationCandidateResolution?> Function(
  RadioStation station, {
  required bool forceRefresh,
});
```

Start the existing station deadline before discovery. For non-Darbhanga stations, skip the callback and execute the current loop unchanged. For Darbhanga, merge unique candidates, try them, force-refresh once after source failures if time remains, and never recurse.

- [ ] **Step 3: Add truthful off-air presentation.**

Add `PlaybackFailureReason.offAir` and `DhwaniPlaybackStatus.offAir`. Use title `Akashvani Darbhanga is currently off air`, subtitle `The broadcaster is not publishing its internet stream right now.`, and retain normal Retry/Next/Previous controls plus `1296 kHz · Darbhanga, Bihar` metadata.

- [ ] **Step 4: Wire SharedPreferences resolver in main and record only confirmed PLAYING as last-known-good.**

Wrap the existing database `onStreamResult` callback: preserve its call exactly, then notify the resolver only when `station.isDarbhanga`. Do not change recording or other station result handling.

- [ ] **Step 5: Run handler and real-network Darbhanga probes.**

Run: `flutter test test/audio_handler_test.dart`
Run when Android is available: `flutter test integration_test/darbhanga_live_probe_test.dart -d <device>`
Expected off-air: clean `offAir`/bounded unavailable, no fake LIVE. Expected active broadcast: PLAYING plus actual media-segment flow.

### Task 5: Regression, Documentation, and v1.4.3 Release

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`
- Modify: `dist/RELEASE_NOTES.md`
- Modify: `test_report.md`
- Modify: `known_issues.md`
- Modify: `decision.md`

**Interfaces:**
- Consumes: verified updater/resolver implementation.
- Produces: version `1.4.3+9`, commit, annotated `v1.4.3` tag, CI release, APK/AAB/checksums.

- [ ] **Step 1: Run formatting and all static/unit/widget tests.**

Run: `dart format .`
Run: `flutter analyze`
Run: `flutter test`
Expected: no analyzer findings and all tests pass.

- [ ] **Step 2: Run Android regression integrations.**

Run the live playback, Darbhanga, controlled-stream, navigation stress, recording, onboarding, and platform-service integration files on an attached Android target. Verify Swiss PLAYING, a German station PLAYING, another Indian station PLAYING, Next/Previous, Play/Pause, Recents, recording, and retro tuner without changing their implementations.

- [ ] **Step 3: Build and verify release artifacts.**

Set `version: 1.4.3+9`, then run `flutter build apk --release` and `flutter build appbundle --release`. Verify `com.prashant.dhwani`, version/build, v2 signature certificate continuity, zip alignment, INTERNET permission, and SHA-256.

- [ ] **Step 4: Append truthful documentation.**

Record official channel `69`, mutable stream-path evidence, redirect behavior, cache TTL/failure policy, off-air/live evidence boundary, test counts, Android target, and all unchanged areas. Do not rewrite older history.

- [ ] **Step 5: Commit, tag, push, and verify protected release CI.**

```bash
git commit -m "fix: make updates and Darbhanga self-healing"
git tag -a v1.4.3 -m "Dhwani v1.4.3 - Darbhanga and Update Detection"
git push origin main
git push origin v1.4.3
```

- [ ] **Step 6: Verify published consumer assets.**

Download the public APK/AAB/checksum files, compare SHA-256, inspect package/version/signature, install the downloaded APK, launch it, and record the public release URL and APK hash.

## Self-Review

- Spec coverage: updater lifecycle/cadence/state/comparison/parsing/403/429/timeout and all 18 resolver cases are assigned to explicit tasks.
- Placeholder scan: no deferred implementation placeholders are present; active-window audio is explicitly a conditional external acceptance result.
- Type consistency: service returns `UpdateCheckResult`; coordinator retains `AppReleaseInfo`; resolver returns a station candidate resolution consumed by the handler callback.
