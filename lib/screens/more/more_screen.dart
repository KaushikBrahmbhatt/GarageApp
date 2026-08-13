import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More Options', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildMenuItem(
            context,
            icon: Icons.two_wheeler,
            iconColor: AppColors.primary,
            title: 'Vehicles',
            subtitle: 'Manage customer vehicles',
            onTap: () => context.push('/vehicles'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.build_outlined,
            iconColor: AppColors.extraWork,
            title: 'Services & Repairs',
            subtitle: 'Manage services, repairs and prices',
            onTap: () => context.push('/services'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.inventory_2_outlined,
            iconColor: Colors.purple,
            title: 'Parts / Inventory',
            subtitle: 'Manage parts stock and prices',
            onTap: () => context.push('/inventory'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.success,
            title: 'Invoices',
            subtitle: 'View invoices & payments',
            onTap: () => context.push('/jobs'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.bar_chart_outlined,
            iconColor: Colors.indigo,
            title: 'Reports',
            subtitle: 'Business reports & revenue analytics',
            onTap: () => context.push('/reports'),
          ),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            iconColor: AppColors.textSecondary,
            title: 'Settings',
            subtitle: 'Garage profile & application settings',
            onTap: () => context.push('/settings'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            iconColor: AppColors.textSecondary,
            title: 'About App',
            subtitle: 'Garage Management System v1.0.0',
            onTap: () {},
          ),
          const Divider(height: 24, color: AppColors.cardBorder),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: 'Logout',
            subtitle: 'Log out of your garage account',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Logout', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to log out of your account?', style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<AuthProvider>().logout();
                        if (context.mounted) {
                          context.go('/login');
                          Fluttertoast.showToast(msg: 'Logged out successfully');
                        }
                      },
                      child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: onTap,
      ),
    );
  }
}
