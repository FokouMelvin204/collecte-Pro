import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/client_provider.dart';
import 'historique_screen.dart';
import 'versement_screen.dart';

/// Tableau de bord client avec solde, statut et historique.
class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool _obscureAccount = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadDashboard();
    });
  }

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return parts;
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A3A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'logocollectpro.png',
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          _currentIndex == 0 
              ? 'Tableau de bord' 
              : (_currentIndex == 1 ? 'Mon Historique' : 'Versement'),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          const HistoriqueScreen(isEmbedded: true),
          VersementScreen(
            isEmbedded: true,
            onNavigateToHistory: () {
              setState(() {
                _currentIndex = 1; // Onglet Historique
              });
            },
            onNavigateToDashboard: () {
              setState(() {
                _currentIndex = 0; // Onglet Dashboard
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2; // Onglet Versement
          });
        },
        backgroundColor: const Color(0xFF1B8A3A),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDashboardTab() {
    return Consumer<ClientProvider>(
      builder: (context, client, _) {
        final dashboard = client.dashboard;

        return RefreshIndicator(
          color: const Color(0xFF1B8A3A),
          onRefresh: () async {
            await context.read<ClientProvider>().loadDashboard();
          },
          child: client.isLoading && dashboard == null
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B8A3A)),
                )
              : client.errorMessage != null
                  ? _buildErrorView(client)
                  : dashboard == null
                      ? const Center(child: Text('Aucune donnée'))
                      : _buildMainContent(dashboard),
        );
      },
    );
  }

  Widget _buildErrorView(ClientProvider client) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur : ${client.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => client.loadDashboard(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(dynamic dashboard) {
    // Calcul des derniers montants
    double dernierDepot = 0;
    double dernierRetrait = 0;

    final list = dashboard.dernieresTransactions;
    if (list.isNotEmpty) {
      for (final t in list) {
        if (t.typePaiement == 'depot' && dernierDepot == 0) {
          dernierDepot = t.montant;
        }
        if (t.typePaiement == 'retrait' && dernierRetrait == 0) {
          dernierRetrait = t.montant;
        }
      }
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // ── HEADER VERT ─────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: const BoxDecoration(
              color: Color(0xFF1B8A3A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Solde Total',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatMontant(dashboard.solde)},00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _obscureAccount
                          ? '**************'
                          : (dashboard.numeroCompte ?? 'Non attribué'),
                      style: const TextStyle(
                        color: Colors.white54,
                        letterSpacing: 4,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscureAccount = !_obscureAccount;
                        });
                      },
                      child: Icon(
                        _obscureAccount
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── STATUT SPECIAL (Attente/Rejet) ─────────
          if (dashboard.statutCompte != 'actif')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildStatusBanner(dashboard.statutCompte),
            ),

          // ── LISTE DES CARTES ────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildValueCard(
                  'Balance Total',
                  '+${_formatMontant(dashboard.solde)},00',
                  const Color(0xFF1B8A3A),
                ),
                const SizedBox(height: 16),
                _buildValueCard(
                  'Dernier Dépôt',
                  '+${_formatMontant(dernierDepot)},00',
                  const Color(0xFF1B8A3A),
                ),
                const SizedBox(height: 16),
                _buildValueCard(
                  'Dernier Retrait',
                  '-${_formatMontant(dernierRetrait)},00',
                  Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String statut) {
    final bool isPending = statut == 'en_attente';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? Colors.orange[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.hourglass_top : Icons.error_outline,
            color: isPending ? Colors.orange[700] : Colors.red[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPending
                  ? 'Compte en attente de validation'
                  : 'Compte rejeté - Contactez le support',
              style: TextStyle(
                color: isPending ? Colors.orange[900] : Colors.red[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home
            IconButton(
              icon: Icon(Icons.home_outlined,
                  color: _currentIndex == 0 ? const Color(0xFF1B8A3A) : Colors.grey, size: 28),
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            // History
            IconButton(
              icon: Icon(Icons.history,
                  color: _currentIndex == 1 ? const Color(0xFF1B8A3A) : Colors.grey, size: 28),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            // Space for FloatingActionButton (+)
            const SizedBox(width: 48),
            // Nav Box (Messagerie)
             IconButton(
               icon: const Icon(Icons.mail_outline, color: Colors.grey, size: 28),
               onPressed: () {
                 _showInfoDialog(
                   "Nav Box",
                   "Cette fonctionnalité permet de consulter les messages envoyés par l'administrateur. En cours de développement."
                 );
               },
             ),
             // Profil
             IconButton(
               icon: const Icon(Icons.person_outline, color: Colors.grey, size: 28),
               onPressed: () {
                 _showInfoDialog(
                   "Profil",
                   "Permet de modifier les données comme le Nom complet, le Numéro de téléphone et l'email. En cours de développement."
                 );
               },
             ),
          ],
        ),
      ),
    );
  }
}
