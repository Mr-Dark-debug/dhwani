import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
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
      ref.read(audioHandlerProvider).pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bootstrapProvider);
    final settings = ref.watch(settingsProvider);
    ref
        .read(audioHandlerProvider)
        .configureNetworkPolicy(
          wifiOnly: settings.wifiOnly,
          preferLowerBitrate: settings.preferLowerBitrate,
          autoReconnect: settings.autoReconnect,
        );
    ref
        .read(recordingServiceProvider)
        .configure(preferredFormat: settings.recordingFormat);
    ref
        .read(audioHandlerProvider)
        .configureEqualizer(
          settings.equalizerPreset,
          customGains: settings.equalizerGains,
        );
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Dhwani — Live Radio',
      theme: DhwaniTheme.light(),
      darkTheme: DhwaniTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              settings.reducedMotion || MediaQuery.disableAnimationsOf(context),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
