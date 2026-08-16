import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_controller.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/dhwani_theme.dart';

class DhwaniApp extends ConsumerWidget {
  const DhwaniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bootstrapProvider);
    final settings = ref.watch(settingsProvider);
    ref
        .read(audioHandlerProvider)
        .configureNetworkPolicy(
          wifiOnly: settings.wifiOnly,
          preferLowerBitrate: settings.preferLowerBitrate,
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
