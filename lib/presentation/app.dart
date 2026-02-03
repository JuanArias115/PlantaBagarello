import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'routes/app_router.dart';

class PlantaBagarelloApp extends ConsumerStatefulWidget {
  const PlantaBagarelloApp({super.key});

  @override
  ConsumerState<PlantaBagarelloApp> createState() => _PlantaBagarelloAppState();
}

class _PlantaBagarelloAppState extends ConsumerState<PlantaBagarelloApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(packageTypeRepositoryProvider).seedDefaultsIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Planta Bagarello',
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
