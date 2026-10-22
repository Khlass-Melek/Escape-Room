import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'features/surveillance/presentation/surveillance_page.dart';

class EscapeRoomApp extends ConsumerWidget {
  const EscapeRoomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'THE ROOM Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}