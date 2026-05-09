import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (gracefully handles unconfigured state)
  await FirebaseService.instance.initialize();

  runApp(const ProviderScope(child: QuantumLabApp()));
}

class QuantumLabApp extends StatelessWidget {
  const QuantumLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuantumLab',
      debugShowCheckedModeBanner: false,
      theme: QuantumLabTheme.light(),
      darkTheme: QuantumLabTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
