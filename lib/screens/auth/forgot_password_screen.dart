import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amical_club/config/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre adresse email')),
      );
      return;
    }

    setState(() => _loading = true);
    
    // Simulate password reset
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _loading = false);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email envoyé !'),
          content: const Text('Un email de réinitialisation a été envoyé à votre adresse.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme le dialog
                if (context.canPop()) {
                  context.pop(); // Retourne à la page précédente
                } else {
                  context.go('/auth/login'); // Retourne à la page de connexion
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth/login');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              'Saisissez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            
            TextField(
              controller: _emailController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: Icon(Icons.email, color: AppTheme.textSecondary),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleResetPassword,
                child: Text(
                  _loading ? 'Envoi...' : 'Envoyer le lien',
                ),
              ),
            ),
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Vous vous souvenez de votre mot de passe ? ',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                TextButton(
                  onPressed: () => context.push('/auth/login'),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}