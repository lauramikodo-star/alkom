import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

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
                  Text(info['nd'] ?? 'Unknown ND'),
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
          _buildDetailRow(context, 'Days Remaining', '${info['balance'] ?? '0'} Days'),
          _buildDetailRow(context, 'Expiry Date', info['dateexp']),
          _buildDetailRow(context, 'NCLI', info['ncli']),
          _buildDetailRow(context, 'Address', info['adresse']),

          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Implement logic to check max speed if available in API
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speed check coming soon')));
            },
            icon: const Icon(Icons.speed),
            label: const Text('Check Max Speed')
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
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }
}
