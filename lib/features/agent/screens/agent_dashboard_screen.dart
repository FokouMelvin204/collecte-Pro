import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/agent_provider.dart';

/// Tableau de bord agent complet avec header, stats, parrainage et versements.
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  String _nom = '';
  String _codeAffiliation = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().loadDashboard();
      context.read<AgentProvider>().loadProfile();
      _loadUserInfo();
    });
  }

  Future<void> _loadUserInfo() async {
    final storage = StorageService();
    final nom = await storage.getString(StorageKeys.userNom) ?? 'Agent';
    final code = await storage.getString(StorageKeys.agentCodeAffiliation) ?? '---';
    if (mounted) {
      setState(() {
        _nom = nom;
        _codeAffiliation = code;
      });
    }
  }

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return parts;
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final jour = d.day.toString().padLeft(2, '0');
      final mois = d.month.toString().padLeft(2, '0');
      final heure = d.hour.toString().padLeft(2, '0');
      final minute = d.minute.toString().padLeft(2, '0');
      return '$jour/$mois/${d.year} à ${heure}h$minute';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateJour() {
    final now = DateTime.now();
    const jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B8A3A),
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'logocollectpro.png',
            height: 72,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.support_agent,
              color: Colors.white,
            ),
          ),
        ),
        title: const Text(
          'Collecte Pro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Se déconnecter',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1B8A3A),
        onRefresh: () async {
          await context.read<AgentProvider>().loadDashboard();
          await _loadUserInfo();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── BLOC 1 : HEADER PERSONNALISÉ ──────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B8A3A), Color(0xFF145C27)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $_nom 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Code agent : $_codeAffiliation',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _formatDateJour(),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── BLOC 2 : GRILLE 2x2 DES STATS ────────────
              Consumer<AgentProvider>(
                builder: (context, agent, _) {
                  if (agent.isLoading && agent.dashboard == null) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF1B8A3A))),
                    );
                  }

                  if (agent.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur : ${agent.errorMessage}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                agent.loadDashboard();
                                _loadUserInfo();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final dashboard = agent.dashboard;
                  if (dashboard == null) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text('Aucune donnée', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          label: "Collecté aujourd'hui",
                          valeur: '${_formatMontant(dashboard.totalCollecteJour)} FCFA',
                          icone: Icons.today,
                          couleur: const Color(0xFF1B8A3A),
                        ),
                        _StatCard(
                          label: 'Ce mois-ci',
                          valeur: '${_formatMontant(dashboard.totalCollecteMois)} FCFA',
                          icone: Icons.calendar_month,
                          couleur: const Color(0xFF1565C0),
                        ),
                        _StatCard(
                          label: 'Mes clients',
                          valeur: '${dashboard.nombreClients}',
                          icone: Icons.people,
                          couleur: const Color(0xFFE65100),
                        ),
                        _StatCard(
                          label: 'Commission mois',
                          valeur: '${_formatMontant(dashboard.commissionMois)} FCFA',
                          icone: Icons.monetization_on,
                          couleur: const Color(0xFF6A1B9A),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ── BLOC 3 : BOUTONS NAVIGATION RAPIDE ───────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.people_outline, color: Color(0xFF1B8A3A)),
                        label: const Text('Mes clients',
                            style: TextStyle(color: Color(0xFF1B8A3A))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B8A3A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/agent/clients'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.monetization_on, color: Color(0xFF1B8A3A)),
                        label: const Text('Commissions',
                            style: TextStyle(color: Color(0xFF1B8A3A))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B8A3A)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/agent/commissions'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── BLOC 4 : SECTION PARRAINAGE ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/agent/parrainage'),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B8A3A), Color(0xFF2ECC71)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2, color: Colors.white, size: 40),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mon QR Code de parrainage',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Faites scanner pour inscrire un client',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── BLOC 5 : DERNIERS VERSEMENTS ─────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Derniers versements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<AgentProvider>(
                      builder: (context, agent, _) {
                        final versements = agent.dashboard?.versementsRecents ?? [];

                        if (versements.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun versement aujourd\'hui',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: versements.length,
                            separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (ctx, i) {
                              final v = versements[i];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF1B8A3A).withValues(alpha: 0.15),
                                  child: Text(
                                    v.clientNom.isNotEmpty
                                        ? v.clientNom[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF1B8A3A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  v.clientNom,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  _formatDate(v.date),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${_formatMontant(v.montant)} FCFA',
                                      style: const TextStyle(
                                        color: Color(0xFF1B8A3A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: v.statut == 'success'
                                            ? Colors.green[50]
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        v.statut == 'success' ? 'Validé' : 'En attente',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: v.statut == 'success'
                                              ? Colors.green[700]
                                              : Colors.orange[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── WIDGET STAT CARD ───────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const _StatCard({
    required this.label,
    required this.valeur,
    required this.icone,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: couleur, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valeur,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8A3A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
