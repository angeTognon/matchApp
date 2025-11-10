import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/providers/match_provider.dart';
import 'package:amical_club/providers/team_provider.dart';
import 'package:amical_club/providers/chat_provider.dart';
import 'package:amical_club/providers/theme_provider.dart';
import 'package:amical_club/providers/search_provider.dart';
import 'package:amical_club/config/app_router.dart';
import 'package:amical_club/config/app_theme.dart';

void main() {
  // Gestion globale des erreurs
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔍 DEBUG: Erreur Flutter: ${details.exception}');
    print('🔍 DEBUG: Stack trace: ${details.stack}');
  };
  
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
            ChangeNotifierProvider(create: (_) => SearchProvider()),
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
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('fr', 'FR'),
            ],
          );
        },
      ),
    );
  }
}