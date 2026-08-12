import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  void _loadUrl() async {
    _urlCtrl.text = await ApiConfig.getBaseUrl();
  }

  void _saveUrl() async {
    await ApiConfig.setBaseUrl(_urlCtrl.text);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server URL Updated')));
  }

  @override
  Widget build(BuildContext context) {
    final garageName = context.watch<AuthProvider>().garageName ?? 'Shree Auto Garage';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Garage Profile Header Card
          Card(
            color: AppColors.surface,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.store, color: AppColors.primary),
              ),
              title: Text(garageName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              subtitle: const Text('Manage profile, address & phone', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),

          _buildTile(Icons.build_outlined, 'Services & Repairs Catalog', 'Manage services & predefined prices', () => context.push('/services')),
          _buildTile(Icons.inventory_2_outlined, 'Parts / Inventory Catalog', 'Manage parts & stock', () => context.push('/inventory')),
          _buildTile(Icons.label_outlined, 'Categories', 'General service, Engine, Brakes...', () {}),
          _buildTile(Icons.credit_card_outlined, 'Payment Methods', 'Cash, UPI, Card settings', () {}),
          _buildTile(Icons.receipt_long_outlined, 'Invoice Settings', 'Invoice prefix & tax GST info', () {}),
          _buildTile(Icons.notifications_outlined, 'Notifications', 'Reminders & service alerts', () {}),
          _buildTile(Icons.cloud_upload_outlined, 'Backup & Restore', 'Data security & backup', () {}),

          const Divider(height: 32, color: AppColors.cardBorder),

          // Server API Settings
          ExpansionTile(
            title: const Text('Server Connection (API URL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Server Base URL',
                        hintText: 'https://kaushik-garage.loca.lt/api',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: _saveUrl,
                        child: const Text('Save Server URL'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AuthProvider>().logout();
                context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        onTap: onTap,
      ),
    );
  }
}
