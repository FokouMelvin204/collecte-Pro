/// Chaînes centralisées de l’application Collecte Pro.
class AppStrings {
  AppStrings._();

  // ——— App ———
  static const String appName = 'Collecte Pro';
  static const String appSubtitle = 'Express Exchange — Akwa';

  // ——— Auth ———
  static const String loginTitle = 'Connexion';
  static const String emailLabel = 'E-mail';
  static const String passwordLabel = 'Mot de passe';
  static const String loginButton = 'Se connecter';
  static const String logout = 'Se déconnecter';
  static const String loginFooterHint =
      'Pas encore inscrit ? Contactez votre agent';

  // ——— Rôles (alignés API / stockage local) ———
  static const String roleAgent = 'agent';
  static const String roleClient = 'client';
  static const String roleAdmin = 'administrateur';

  // ——— Agent ———
  static const String agentDashboardTitle = 'Espace Agent';
  static const String mesClients = 'Mes clients';
  static const String commissions = 'Commissions';
  static const String parrainage = 'Parrainage';

  // ——— Client ———
  static const String inscriptionTitle = 'Inscription';
  static const String clientDashboardTitle = 'Espace Client';
  static const String versement = 'Versement';
  static const String historique = 'Historique';

  // ——— Admin ———
  static const String adminDashboardTitle = 'Espace Administrateur';
  static const String validationClients = 'Validation clients';
  static const String gestionAgents = 'Gestion des agents';
  static const String rapports = 'Rapports';

  // ——— Générique ———
  static const String loading = 'Chargement…';
  static const String errorGeneric = 'Une erreur est survenue.';
  static const String retry = 'Réessayer';
}
