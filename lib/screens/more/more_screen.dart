import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/garage.dart';
import '../../services/garage_service.dart';
import '../../widgets/rpm_gauge_loader.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showEditGarageSheet(BuildContext context) async {
    RpmGaugeLoader.show(context, statusMessages: ['Loading profile details']);
    Garage? garage;
    try {
      garage = await GarageService.getGarage();
    } catch (_) {}
    if (context.mounted) RpmGaugeLoader.hide(context);

    if (!context.mounted) return;

    final nameCtrl = TextEditingController(text: garage?.name ?? context.read<AuthProvider>().garageName ?? '');
    final ownerCtrl = TextEditingController(text: garage?.ownerName ?? context.read<AuthProvider>().staffName ?? '');
    final phoneCtrl = TextEditingController(text: garage?.phone ?? '');
    final emailCtrl = TextEditingController(text: garage?.email ?? '');
    final addressCtrl = TextEditingController(text: garage?.address ?? '');

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edit Profile & Garage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Garage Name *', hintText: 'e.g. Shree Auto Garage', prefixIcon: Icon(Icons.store, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ownerCtrl,
                  decoration: const InputDecoration(labelText: 'Owner / Manager Name', hintText: 'e.g. Rajesh Sharma', prefixIcon: Icon(Icons.person_outline, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. +91 9876543210', prefixIcon: Icon(Icons.phone, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', hintText: 'e.g. contact@garage.com', prefixIcon: Icon(Icons.email, color: AppColors.primary)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address', hintText: 'e.g. Shop 4, Station Road, Pune', prefixIcon: Icon(Icons.location_on, color: AppColors.primary)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) {
                              Fluttertoast.showToast(msg: 'Garage Name is required');
                              return;
                            }
                            setSheetState(() => isSaving = true);
                            try {
                              final authProvider = context.read<AuthProvider>();
                              final updated = await GarageService.updateGarage(
                                name: nameCtrl.text.trim(),
                                ownerName: ownerCtrl.text.trim().isEmpty ? null : ownerCtrl.text.trim(),
                                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                              );

                              await authProvider.updateGarageName(updated.name);
                              if (ownerCtrl.text.trim().isNotEmpty) {
                                await authProvider.updateStaffName(ownerCtrl.text.trim());
                              }

                              if (ctx.mounted) Navigator.pop(ctx);
                              Fluttertoast.showToast(msg: 'Profile updated successfully!');
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Failed to update profile: ${e.toString().replaceFirst('Exception: ', '')}');
                            } finally {
                              if (ctx.mounted) setSheetState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.watch<AuthProvider>().garageName ?? 'Garage Management',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Owner: ${context.watch<AuthProvider>().staffName ?? 'Garage Owner'}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            iconColor: AppColors.primary,
            title: 'Profile Update',
            subtitle: 'Update garage name, owner & contact details',
            onTap: () => _showEditGarageSheet(context),
          ),
          _buildMenuItem(
            context,
            icon: Icons.two_wheeler,
            iconColor: Colors.amber.shade800,
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
            icon: Icons.bar_chart_outlined,
            iconColor: Colors.indigo,
            title: 'Reports',
            subtitle: 'Business reports & revenue analytics',
            onTap: () => context.push('/reports'),
          ),
          const Divider(height: 24, color: AppColors.cardBorder),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
