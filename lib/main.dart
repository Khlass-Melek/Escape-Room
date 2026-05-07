import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/mqtt_service.dart';
import 'core/services/public_mqtt_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yjbjkhymnzphjybsgrto.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqYmpraHltbnpwaGp5YnNncnRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NzUwOTEsImV4cCI6MjA4NzQ1MTA5MX0.9PZGYWbxMoizbs0u0gU55CFROj44d8I3YJK879oYjPk',
  );

  // Initialiser MQTT en arrière-plan sans bloquer l'interface
  MqttService().connect().catchError((e) {
    print("Erreur de connexion MQTT local: $e");
  });

  PublicMqttService().connect().catchError((e) {
    print("Erreur de connexion Public MQTT: $e");
  });

  runApp(const ProviderScope(child: EscapeRoomApp()));
}