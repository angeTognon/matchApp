import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:amical_club/providers/auth_provider.dart';
import 'package:amical_club/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndNavigate();
  }

  _checkAuthenticationAndNavigate() async {
    // Attendre un peu pour l'effet visuel
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Vérifier l'authentification
      await authProvider.checkAuthentication();
      
      if (mounted) {
        // Rediriger selon le statut de connexion
        if (authProvider.isAuthenticated) {
          context.go('/main');
        } else {
          context.go('/auth/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogoLarge(),
            const SizedBox(height: 20),
            const Text(
              'Amical Club',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connecter les coachs de football',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}