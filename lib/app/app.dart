import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/dhwani_log.dart';
import '../core/settings/settings_controller.dart';
import '../core/updater/app_update_coordinator.dart';
import '../core/updater/app_update_service.dart';
import '../core/updater/app_update_sheet.dart';
import '../core/widgets/home_widget_sync.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/dhwani_theme.dart';

class DhwaniApp extends ConsumerStatefulWidget {
  const DhwaniApp({super.key});

  @override
  ConsumerState<DhwaniApp> createState() => _DhwaniAppState();
}

class _DhwaniAppState extends ConsumerState<DhwaniApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_checkForUpdate(UpdateTrigger.coldStart));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdate(UpdateTrigger.resume));
    }
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        !ref.read(settingsProvider).backgroundPlayback) {
      unawaited(
        ref.read(audioHandlerProvider).pause().catchError((
          Object error,
          StackTrace stack,
        ) {
          DhwaniLog.player('Lifecycle pause failed safely', error, stack);
        }),
      );
    }
  }

  Future<void> _checkForUpdate(UpdateTrigger trigger) async {
    final coordinator = ref.read(appUpdateCoordinatorProvider);
    final result = await coordinator.checkAutomatically(trigger);
    if (!mounted || result is! UpdateAvailable) return;
    final release = result.release;
    final navigatorContext = ref.read(rootNavigatorKeyProvider).currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    if (!coordinator.takePresentation(release.tagName)) return;
    unawaited(
      AppUpdateSheet.show(
        navigatorContext,
        release: release,
        updateService: ref.read(appUpdateServiceProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bootstrapProvider);
    final settings = ref.watch(settingsProvider);

    ref.listen(settingsProvider, (previous, next) {
      ref
          .read(audioHandlerProvider)
          .configureNetworkPolicy(
            wifiOnly: next.wifiOnly,
            preferLowerBitrate: next.preferLowerBitrate,
            autoReconnect: next.autoReconnect,
          );
      ref
          .read(recordingServiceProvider)
          .configure(preferredFormat: next.recordingFormat);
      ref
          .read(audioHandlerProvider)
          .configureEqualizer(
            next.equalizerPreset,
            customGains: next.equalizerGains,
          );
    });

    ref.listen(favouritesProvider, (previous, next) {
      final favs = next.value;
      if (favs != null) {
        unawaited(HomeWidgetSync.update(favourites: favs));
      }
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Dhwani — Live Radio',
      theme: DhwaniTheme.light(),
      darkTheme: DhwaniTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
