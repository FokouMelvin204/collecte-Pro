import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Délai pour simuler le chargement et montrer le logo
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Vérifier si l'onboarding a déjà été vu
    final storage = StorageService();
    final hasSeenOnboarding = await storage.getBool(StorageKeys.hasSeenOnboarding) ?? false;

    if (!hasSeenOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
    } else {
      // Redirige vers l'AuthGate qui gère la session.
      Navigator.of(context).pushReplacementNamed(AppRouter.initial);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6), // Fond gris très clair comme sur l'image
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec ombre légère pour correspondre au style
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'logocollectpro.png',
                height: 240, // Un peu plus grand pour le ratio portrait
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.account_balance_wallet,
                  size: 120,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Texte COLLECTE PRO style doré/marron comme sur l'image
            const Text(
              'COLLECTE PRO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFFB8860B), // Couleur dorée/bronze
              ),
            ),
            const SizedBox(height: 40),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chargement...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
