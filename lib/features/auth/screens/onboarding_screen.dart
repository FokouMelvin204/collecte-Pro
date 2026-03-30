import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../router/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Chaque jour, vos\nencaissements sous\ncontrôle',
      'description':
          'Simplifiez vos collectes, sécurisez\nvos finances, La solution\nintelligente pour vos collectes\nquotidiennes',
      'image': 'onboarding1.png',
    },
    {
      'title': 'Simplifiez la gestion\nde vos impayés',
      'description':
          'Identifier rapidement les retards de\npaiement, de relancer efficacement\nvos clients et de suivre l\'évolution\ndes remboursements',
      'image': 'onboarding2.png',
    },
  ];

  Future<void> _completeOnboarding() async {
    await StorageService().setBool(StorageKeys.hasSeenOnboarding, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Image onboarding en haut (hauteur 32%)
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.32,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(_pages[index]['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Titre
                              Text(
                                _pages[index]['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Description
                              Text(
                                _pages[index]['description']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Indicateur de page (points)
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (indexIndicator) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentPage == indexIndicator ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == indexIndicator ? AppColors.primary : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Boutons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Bouton Continue / Commencer
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_currentPage < _pages.length - 1) {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _completeOnboarding();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    _currentPage == 0 ? 'Continue' : 'Commencer',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Bouton Se Connecter
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _completeOnboarding,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'Se Connecter',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCentralIllustration() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // On peut mettre des icônes ici pour simuler la maquette
            Icon(Icons.people_outline, size: 40, color: Colors.green[700]),
            Positioned(top: 20, child: Icon(Icons.calendar_today, size: 24, color: Colors.orange)),
            Positioned(bottom: 20, child: Icon(Icons.pie_chart_outline, size: 24, color: Colors.blue)),
            Positioned(left: 20, child: Icon(Icons.account_balance_wallet_outlined, size: 24, color: Colors.brown)),
            Positioned(right: 20, child: Icon(Icons.message_outlined, size: 24, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
