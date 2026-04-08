
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = 'https://yjbjkhymnzphjybsgrto.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlqYmpraHltbnpwaGp5YnNncnRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4NzUwOTEsImV4cCI6MjA4NzQ1MTA5MX0.9PZGYWbxMoizbs0u0gU55CFROj44d8I3YJK879oYjPk';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  final supabase = Supabase.instance.client;

  print('Testing bucket: "audio"');
  try {
    final List<FileObject> objects = await supabase.storage.from('audio').list();
    print('Found ${objects.length} items in root:');
    for (var obj in objects) {
      print(' - ${obj.name} (ID: ${obj.id}, Metadata: ${obj.metadata})');
    }
    
    if (objects.isEmpty) {
      print('WARNING: Root is empty. Checking if bucket "audio" even exists...');
      try {
        final buckets = await supabase.storage.listBuckets();
        print('Available buckets: ${buckets.map((b) => b.name).toList()}');
      } catch (e) {
        print('Error listing buckets: $e');
      }
    }
  } catch (e) {
    print('Error listing bucket "audio": $e');
    if (e.toString().contains('403')) {
      print('POSSIBLE CAUSE: RLS Policies are blocking "select" access on Storage.');
    }
  }

  exit(0);
}
