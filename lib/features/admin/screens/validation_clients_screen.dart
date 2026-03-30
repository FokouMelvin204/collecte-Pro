import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/admin_provider.dart';

class ValidationClientsScreen extends StatefulWidget {
  const ValidationClientsScreen({super.key});

  @override
  State<ValidationClientsScreen> createState() => _ValidationClientsScreenState();
}

class _ValidationClientsScreenState extends State<ValidationClientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadClientsAttente();
    });
  }

  String _formatDate(String s) {
    try {
      final d = DateTime.parse(s);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return s;
    }
  }

  void _showCni(String? path) {
    if (path == null) return;
    // En MVP, on affiche juste une info ou un dialog avec l'URL
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Justificatif CNI'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Fichier : $path'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, int id, String nom, bool valider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(valider ? 'Valider le client' : 'Rejeter le client'),
        content: Text('Voulez-vous vraiment ${valider ? "valider" : "rejeter"} le dossier de $nom ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final admin = context.read<AdminProvider>();
              
              final ok = valider 
                ? await admin.validerClient(id) 
                : await admin.rejeterClient(id);
              
              if (mounted) {
                if (ok) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(valider ? 'Client validé avec succès' : 'Client rejeté'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (admin.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(admin.errorMessage!),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: valider ? Colors.green : Colors.red),
            child: Text(valider ? 'Confirmer Validation' : 'Confirmer Rejet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final list = admin.clientsAttente;

    return Scaffold(
      appBar: AppBar(title: const Text('Validations en attente')),
      body: admin.isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? const Center(child: Text('Aucun client en attente'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final c = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c['nom'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  _formatDate(c['date_inscription']),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Tél : ${c['telephone']}'),
                            Text('Email : ${c['email']}'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Parrainé par : ${c['agent_nom']} (${c['code_affiliation']})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (c['cni_path'] != null)
                                  OutlinedButton.icon(
                                    onPressed: () => _showCni(c['cni_path']),
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('Voir CNI'),
                                  ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _confirmAction(context, c['id'], c['nom'], false),
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Rejeter',
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _confirmAction(context, c['id'], c['nom'], true),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Valider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
