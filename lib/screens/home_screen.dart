import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'auth/login_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _numberCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();
  final _4gNumberCtrl = TextEditingController();
  final _4gVoucherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _scanVoucher() async {
    final state = context.read<AppState>();
    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Scan Source'),
        actions: <Widget>[
          TextButton(
            child: const Text('Camera'),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
          TextButton(
            child: const Text('Gallery'),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      _showSnack('⚡ Scanning with AI...', color: Colors.orange);
      try {
        final code = await state.geminiApi.extractVoucherCode(File(image.path));

        // Determine which tab is active to populate correct field
        if (_tabController.index == 2) { // 4G Tab
           _4gVoucherCtrl.text = code;
        } else if (_tabController.index == 1) { // ADSL/Fibre Tab
           _voucherCtrl.text = code;
        }
        _showSnack('✅ Voucher code found!', color: Colors.green);
      } catch (e) {
        _showSnack('❌ Error: $e', color: Colors.red);
      }
    }
  }

  void _showApiResponseDialog(Map<String, dynamic> response) {
    final bool isSuccess = response['succes'] == '1' || response.containsKey('num_trans');
    final String title = isSuccess ? '✅ Recharge Successful!' : '❌ Recharge Failed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: response.entries.map((entry) {
              final key = entry.key.replaceAll('_', ' ').toUpperCase();
              final value = entry.value?.toString() ?? 'N/A';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      TextSpan(text: '$key: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: value),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AT DZ Recharge'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
             Tab(icon: Icon(Icons.person), text: "Account"),
             Tab(icon: Icon(Icons.router), text: "ADSL/Fibre"),
             Tab(icon: Icon(Icons.wifi_tethering), text: "4G LTE"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Account (Login/Dashboard)
          state.isLoggedIn
              ? const AccountScreen()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Manage your My Idoom Account"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen())
                          );
                        },
                        child: const Text("Login / Register")
                      ),
                    ],
                  ),
                ),

          // Tab 2: ADSL/Fibre (Anonymous)
          _buildAdslTab(state),

          // Tab 3: 4G LTE (Anonymous)
          _build4gTab(state),
        ],
      ),
    );
  }

  Widget _buildAdslTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Quick Actions (No Login Required)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _numberCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone / Line number',
              hintText: '021.. or 05..',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Voucher code',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _scanVoucher,
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Scan Voucher',
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: state.loading
                    ? null
                    : () async {
                        final n = _numberCtrl.text.trim();
                        if (n.isEmpty) return _showSnack('Enter number');
                        await state.fetchInfo(n);
                        final info = state.lineInfo;
                        if (info?['found'] == true) {
                          _showSnack('Found ${info!['type']} | NCLI: ${info['ncli']}');
                        } else {
                          _showSnack('Not found', color: Colors.red);
                        }
                      },
                icon: const Icon(Icons.info_outline),
                label: const Text('Line infos'),
              ),
              ElevatedButton.icon(
                onPressed: state.loading
                    ? null
                    : () async {
                        final n = _numberCtrl.text.trim();
                        final v = _voucherCtrl.text.trim();
                        if (n.isEmpty || v.isEmpty) {
                          return _showSnack('Enter number and voucher');
                        }
                        final res = await state.pay(n, v);
                        _showApiResponseDialog(res);
                      },
                icon: const Icon(Icons.payment),
                label: const Text('Recharge'),
              ),
              ElevatedButton.icon(
                onPressed: state.loading
                    ? null
                    : () async {
                        final n = _numberCtrl.text.trim();
                        if (n.isEmpty) return _showSnack('Enter number');
                        final res = await state.debt(n);
                        if (res['succes'] == '1') {
                          _showSnack('Debt exists', color: Colors.orange);
                        } else {
                          _showSnack(res['message']?.toString() ?? 'No debt',
                              color: Colors.green);
                        }
                      },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Debt info'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.lineInfo != null) _InfoCard(data: state.lineInfo!),
        ],
      ),
    );
  }

  Widget _build4gTab(AppState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _4gNumberCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '4G LTE Line number',
              hintText: '213...',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                 child: TextField(
                  controller: _4gVoucherCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Voucher code',
                    prefixIcon: Icon(Icons.confirmation_number),
                  ),
                ),
              ),
               const SizedBox(width: 8),
              IconButton(
                onPressed: _scanVoucher,
                icon: const Icon(Icons.camera_alt),
                tooltip: 'Scan Voucher',
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: state.loading
                    ? null
                    : () async {
                        final n = _4gNumberCtrl.text.trim();
                        if (n.isEmpty) return _showSnack('Enter 4G number');
                        await state.fetch4gInfo(n);
                        final info = state.line4gInfo;
                        if (info?['succes'] == '1') {
                          _showSnack('Found ${info!['type']} | NCLI: ${info['ncli']}');
                        } else {
                          _showSnack('Not found', color: Colors.red);
                        }
                      },
                icon: const Icon(Icons.info_outline),
                label: const Text('Get 4G LTE Info'),
              ),
              ElevatedButton.icon(
                onPressed: state.loading
                    ? null
                    : () async {
                        final n = _4gNumberCtrl.text.trim();
                        final v = _4gVoucherCtrl.text.trim();
                        if (n.isEmpty || v.isEmpty) {
                          return _showSnack('Enter 4G number and voucher');
                        }
                        final res = await state.pay(n, v);
                        _showApiResponseDialog(res);
                      },
                icon: const Icon(Icons.payment),
                label: const Text('Recharge 4G'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.loading) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          if (state.line4gInfo != null)
            _4gInfoCard(data: state.line4gInfo!),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data['found'] != true) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_circle),
              const SizedBox(width: 8),
              Text('${data['system']} - ${data['type']}',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text('NCLI: ${data['ncli']}'),
            Text('Offer: ${data['offer']}'),
            Text('Client: ${data['client']}'),
          ],
        ),
      ),
    );
  }
}

class _4gInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _4gInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data['succes'] != '1') return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.four_g_mobiledata),
              const SizedBox(width: 8),
              Text('${data['type']}',
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            Text('NCLI: ${data['ncli']}'),
          ],
        ),
      ),
    );
  }
}
