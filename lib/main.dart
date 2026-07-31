import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ugfedyvoidzqiqswlhdr.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVnZmVkeXZvaWR6cWlxc3dsaGRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU0MTc4MDMsImV4cCI6MjEwMDk5MzgwM30.V0hVisWizDQWzLU7qnyw00z7bzn1GrT85oo8SzSkdCA',
  );

  runApp(const ProviderScope(child: MyApp()));
}