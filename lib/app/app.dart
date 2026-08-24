import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
import '../core/logging/dhwani_log.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
