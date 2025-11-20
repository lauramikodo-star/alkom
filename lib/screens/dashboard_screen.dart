import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.userProfile;

    if (user == null) {
      return const Center(child: Text('No user data available'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Idoom Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               showDialog(context: context, builder: (ctx) => AlertDialog(
                 title: const Text('Logout'),
                 content: const Text('Are you sure you want to logout?'),
                 actions: [
                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                   TextButton(onPressed: () {
                     Navigator.pop(ctx);
                     state.logout();
                   }, child: const Text('Logout')),
                 ],
               ));
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBalanceCard(context, user),
              const SizedBox(height: 16),
              _buildInfoCard(context, user),
              const SizedBox(height: 16),
              _buildSubscriptionCard(context, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, Map<String, dynamic> user) {
    final balance = user['balance'] ?? '0.00';
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Current Balance', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '$balance DZD',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
             Text(
              'Expires: ${user['dateexp'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Map<String, dynamic> user) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('${user['prenom']} ${user['nom']}'),
            subtitle: const Text('Subscriber Name'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text('${user['nd']}'),
            subtitle: const Text('Landline Number'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: Text('${user['ncli']}'),
            subtitle: const Text('Client ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, Map<String, dynamic> user) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.wifi),
            title: Text('${user['offre']}'),
            subtitle: const Text('Current Offer'),
          ),
           const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('${user['status']}'),
            subtitle: const Text('Line Status'),
            trailing: user['status'] == 'Actif'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.money_off),
            title: Text('${user['dette']}'),
            subtitle: const Text('Debt'),
             trailing: (user['dette'] != null && user['dette'].toString() != '0')
                ? const Icon(Icons.warning, color: Colors.orange)
                : const Icon(Icons.check, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
