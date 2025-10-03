import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/match_provider.dart';
import 'package:amical_club/providers/team_provider.dart';
import 'package:amical_club/providers/chat_provider.dart';
import 'package:amical_club/providers/theme_provider.dart';
import 'package:amical_club/config/app_router.dart';
import 'package:amical_club/config/app_theme.dart';

void main() {
  runApp(const AmicalClubApp());
}

class AmicalClubApp extends StatelessWidget {
  const AmicalClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Amical Club',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}