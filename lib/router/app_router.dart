import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/gestion_agents_screen.dart';
import '../features/admin/screens/rapports_screen.dart';
import '../features/admin/screens/validation_clients_screen.dart';
import '../features/agent/screens/agent_dashboard_screen.dart';
import '../features/agent/screens/commissions_screen.dart';
import '../features/agent/screens/mes_clients_screen.dart';
import '../features/agent/screens/parrainage_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/client/screens/client_dashboard_screen.dart';
import '../features/client/screens/historique_screen.dart';
import '../features/client/screens/inscription_screen.dart';
import '../features/client/screens/versement_screen.dart';

/// Routes nommées et contrôle d’accès par session / rôle.
class AppRouter {
  AppRouter._();

  static const String initial = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  static const String agentDashboard = '/agent/dashboard';
  static const String agentClients = '/agent/clients';
  static const String agentCommissions = '/agent/commissions';
  static const String agentParrainage = '/agent/parrainage';

  static const String clientDashboard = '/client/dashboard';
  static const String clientInscription = '/client/inscription';
  static const String clientVersement = '/client/versement';
  static const String clientHistorique = '/client/historique';

  static const String adminDashboard = '/admin/dashboard';
  static const String adminValidations = '/admin/validations';
  static const String adminAgents = '/admin/agents';
  static const String adminRapports = '/admin/rapports';

  /// Garde : session obligatoire + rôle attendu.
  static Widget guardRoute(BuildContext context, String requiredRole, Widget screen) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }
    if (auth.role != requiredRole) {
      return const LoginScreen();
    }
    return screen;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name ?? initial;

    // Analyse du lien d'inscription (Flutter Web)
    // On utilise une détection plus robuste pour le Web
    if (name.contains('inscription') || name.endsWith('inscription')) {
      return MaterialPageRoute<void>(
        builder: (context) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          if (auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              auth.forceLogout();
            });
          }
          return const InscriptionScreen();
        },
        settings: settings,
      );
    }

    return MaterialPageRoute<void>(
      builder: (context) {
        final auth = Provider.of<AuthProvider>(context, listen: false);

        if (name == initial) {
          return const AuthGate();
        }

        if (name == splash) {
          return const SplashScreen();
        }

        if (name == onboarding) {
          return const OnboardingScreen();
        }

        if (name == login) {
          return const LoginScreen();
        }

        if (name == clientInscription) {
          return const InscriptionScreen();
        }

        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        switch (name) {
          case agentDashboard:
            return guardRoute(context, AppStrings.roleAgent, const AgentDashboardScreen());
          case agentClients:
            return guardRoute(context, AppStrings.roleAgent, const MesClientsScreen());
          case agentCommissions:
            return guardRoute(context, AppStrings.roleAgent, const CommissionsScreen());
          case agentParrainage:
            return guardRoute(context, AppStrings.roleAgent, const ParrainageScreen());

          case clientDashboard:
            return guardRoute(context, AppStrings.roleClient, const ClientDashboardScreen());
          case clientInscription:
            return guardRoute(context, AppStrings.roleClient, const InscriptionScreen());
          case clientVersement:
            return guardRoute(context, AppStrings.roleClient, const VersementScreen());
          case clientHistorique:
            return guardRoute(context, AppStrings.roleClient, const HistoriqueScreen());

          case adminDashboard:
            return guardRoute(context, AppStrings.roleAdmin, const AdminDashboardScreen());
          case adminValidations:
            return guardRoute(context, AppStrings.roleAdmin, const ValidationClientsScreen());
          case adminAgents:
            return guardRoute(context, AppStrings.roleAdmin, const GestionAgentsScreen());
          case adminRapports:
            return guardRoute(context, AppStrings.roleAdmin, const RapportsScreen());

          default:
            return const AuthGate();
        }
      },
      settings: settings,
    );
  }
}

/// Splash puis session : [AuthProvider.checkSession] au montage.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'collectpro.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 100,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
          );
        }

        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        if (auth.isAgent) {
          return const AgentDashboardScreen();
        }
        if (auth.isClient) {
          return const ClientDashboardScreen();
        }
        if (auth.isAdmin) {
          return const AdminDashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
