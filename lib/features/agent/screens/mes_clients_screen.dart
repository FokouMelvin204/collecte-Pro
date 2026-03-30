import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/agent_provider.dart';
import '../../../core/models/client_model.dart';

/// Liste des clients parrainés par l'agent.
class MesClientsScreen extends StatefulWidget {
  const MesClientsScreen({super.key});

  @override
  State<MesClientsScreen> createState() => _MesClientsScreenState();
}

class _MesClientsScreenState extends State<MesClientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().loadClients();
    });
  }

  String _formatMontant(double montant) {
    final parts = montant.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
    return '$parts FCFA';
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final jour = d.day.toString().padLeft(2, '0');
      final mois = d.month.toString().padLeft(2, '0');
      return '$jour/$mois/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Consumer<AgentProvider>(
          builder: (context, agent, _) {
            final count = agent.clients.isNotEmpty
                ? '(${agent.clients.length})'
                : '';
            return Text('Mes Clients $count');
          },
        ),
      ),
      body: Consumer<AgentProvider>(
        builder: (context, agent, _) {
          if (agent.isLoading && agent.clients.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (agent.clients.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agent.clients.length,
            itemBuilder: (context, index) {
              final client = agent.clients[index];
              return _ClientCard(
                client: client,
                formatMontant: _formatMontant,
                formatDate: _formatDate,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun client pour l\'instant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Partagez votre QR Code pour en avoir !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: AppButton(
                label: 'Voir mon QR Code',
                icon: Icons.qr_code,
                onPressed: () => Navigator.pushNamed(context, '/agent/parrainage'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un client.
class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.formatMontant,
    required this.formatDate,
  });

  final ClientModel client;
  final String Function(double) formatMontant;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  radius: 26,
                  child: Text(
                    client.initiales,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.telephone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: client.statutColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: client.statutColor),
                  ),
                  child: Text(
                    client.statutLabel,
                    style: TextStyle(
                      color: client.statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (client.numeroCompte != null && client.numeroCompte!.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        client.numeroCompte!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                else
                  const Spacer(),
                if (client.solde > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Solde',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        formatMontant(client.solde),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Inscrit le ${formatDate(client.dateInscription)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
