import 'package:escape_room_admin/router.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/messages/presentation/message_page.dart';
// import 'features/surveillance/presentation/surveillance_page.dart';

class EscapeRoomApp extends StatelessWidget {
  const EscapeRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Escape Room Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router, // ← this replaces home: & Navigator
    );
  }
}