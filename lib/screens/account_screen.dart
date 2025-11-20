import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _showSpeedsDialog(BuildContext context, String speedListStr) {
    final speeds = speedListStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Available Speeds'),
        content: speeds.isNotEmpty
          ? SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: speeds.map((s) => ListTile(
                  leading: const Icon(Icons.speed, color: Colors.blue),
                  title: Text(s),
                )).toList(),
              ),
            )
          : const Text("ℹ️ No clear speed upgrade information found in your account data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final info = state.accountInfo;

    if (info == null) {
       return const Center(child: Text('No account info available.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${info['prenom'] ?? ''} ${info['nom'] ?? ''}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(info['nd'] ?? 'Unknown ND', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    '${info['credit'] ?? '0'} DA',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.green),
                  ),
                  const Text('Balance'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Offer', info['offre']),
          _buildDetailRow(context, 'Speed', '${info['speed'] ?? '?'} Mbps'),
          _buildDetailRow(context, 'Status', info['status']),
          _buildDetailRow(context, 'Type', info['type1']),
          const Divider(),
          _buildDetailRow(context, 'Days Remaining', '${info['balance'] ?? '0'} Days'),
          _buildDetailRow(context, 'Expiry Date', info['dateexp']),
          const Divider(),
          _buildDetailRow(context, 'NCLI', info['ncli']),
          _buildDetailRow(context, 'Mobile', info['mobile']),
          _buildDetailRow(context, 'Email', info['email']),
          _buildDetailRow(context, 'Address', info['adresse']),

          const SizedBox(height: 24),
          if (info['listOffreDebit'] != null)
            ElevatedButton.icon(
              onPressed: () => _showSpeedsDialog(context, info['listOffreDebit'].toString()),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Check Available Speeds')
            )
          else
             ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Speed Check Unavailable')
            ),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
               context.read<AppState>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout')
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'N/A', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
