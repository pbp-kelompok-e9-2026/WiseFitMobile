import 'package:flutter/material.dart';

import 'services/worth_to_buy_api.dart';
import 'screens/worth_to_buy_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.api});
  final WorthToBuyApi? api;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final WorthToBuyApi api = widget.api ?? WorthToBuyApi();
  @override
  void dispose() {
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: api,
    builder: (context, _) => MaterialApp(
      key: ValueKey(api.user?.id),
      title: 'WiseFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff4efe6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff626947),
          surface: const Color(0xfff4efe6),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff4efe6),
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xfffffcf7),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xfffffcf7),
          margin: EdgeInsets.only(bottom: 12),
        ),
      ),
      home: WorthToBuyScreen(api: api),
    ),
  );
}
