import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadRapports();
    });
  }

  String _formatMontant(double m) {
    return m.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ').trim();
  }

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final data = admin.rapports;

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports & Synthèse')),
      body: admin.isLoading && data == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(data),
                  const SizedBox(height: 24),
                  Text(
                    'Collecte par agent (Mois en cours)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (data?['collecte_par_agent'] != null)
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (data!['collecte_par_agent'] as List).length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final a = data['collecte_par_agent'][index];
                          return ListTile(
                            title: Text(a['agent_nom']),
                            subtitle: Text(a['code']),
                            trailing: Text(
                              '${_formatMontant(a['total'])} F',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Dernières transactions globales',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (data?['transactions_recentes'] != null)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: (data!['transactions_recentes'] as List).length,
                      itemBuilder: (context, index) {
                        final t = data['transactions_recentes'][index];
                        final bool isSuccess = t['statut'] == 'success';
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.payment,
                              color: isSuccess ? Colors.green : Colors.red,
                            ),
                            title: Text(t['client_nom']),
                            subtitle: Text(_formatDate(t['date'])),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatMontant(t['montant'])} F',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  t['type_paiement'],
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic>? data) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Période : ${data?['periode'] ?? '-'}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Collecte', '${_formatMontant(data?['total_collecte'] ?? 0)} F'),
                _buildSummaryItem('Commissions', '${_formatMontant(data?['total_commissions'] ?? 0)} F'),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            Text(
              '${data?['nombre_transactions'] ?? 0} transactions réussies ce mois',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
