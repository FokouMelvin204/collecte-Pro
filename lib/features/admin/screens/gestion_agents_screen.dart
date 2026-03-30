import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import '../providers/admin_provider.dart';

class GestionAgentsScreen extends StatefulWidget {
  const GestionAgentsScreen({super.key});

  @override
  State<GestionAgentsScreen> createState() => _GestionAgentsScreenState();
}

class _GestionAgentsScreenState extends State<GestionAgentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAgents();
    });
  }

  String _formatMontant(double m) {
    return m.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (x) => '${x[1]} ').trim();
  }

  void _showAddAgentDialog() {
    final formKey = GlobalKey<FormState>();
    final nom = TextEditingController();
    final email = TextEditingController();
    final tel = TextEditingController();
    final pass = TextEditingController();
    final taux = TextEditingController(text: '2.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvel Agent'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(controller: nom, label: 'Nom complet', validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                AppInput(controller: email, label: 'Email', keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'Requis' : null),
                const SizedBox(height: 12),
                AppInput(controller: tel, label: 'Téléphone', keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                AppInput(controller: pass, label: 'Mot de passe', obscureText: true, validator: (v) => v!.length < 6 ? '6 car. min' : null),
                const SizedBox(height: 12),
                AppInput(controller: taux, label: 'Taux commission (%)', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final messenger = ScaffoldMessenger.of(context);
                final admin = context.read<AdminProvider>();
                final ok = await admin.creerAgent({
                  'nom': nom.text.trim(),
                  'email': email.text.trim(),
                  'telephone': tel.text.trim(),
                  'mot_de_passe': pass.text,
                  'taux_commission': double.tryParse(taux.text) ?? 2.0,
                });
                if (mounted && ok) {
                  Navigator.of(context).pop();
                  messenger.showSnackBar(const SnackBar(content: Text('Agent créé')));
                }
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final list = admin.agents;

    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Agents')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAgentDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: admin.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final a = list[index];
                final bool isActive = a['statut'] == 'actif';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.green[50] : Colors.red[50],
                      child: Icon(Icons.person, color: isActive ? Colors.green : Colors.red),
                    ),
                    title: Text(a['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${a['code_affiliation']} • ${a['nb_clients']} clients'),
                    trailing: Switch(
                      value: isActive,
                      onChanged: (_) => admin.toggleAgentStatut(a['id'], a['statut']),
                      activeTrackColor: Colors.green,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow('Email', a['email']),
                            _buildInfoRow('Téléphone', a['telephone']),
                            _buildInfoRow('Taux', '${a['taux_commission']}%'),
                            const Divider(),
                            _buildInfoRow('Total Collecté', '${_formatMontant(a['total_collecte'])} F', isBold: true),
                            _buildInfoRow('Commissions', '${_formatMontant(a['total_commissions'])} F', color: Colors.orange),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
