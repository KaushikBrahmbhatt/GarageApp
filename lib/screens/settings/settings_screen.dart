import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../services/garage_service.dart';

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

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _loadUrl() async {
    _urlCtrl.text = await ApiConfig.getBaseUrl();
  }

  void _saveUrl() async {
    await ApiConfig.setBaseUrl(_urlCtrl.text);
    if (mounted) Fluttertoast.showToast(msg: 'Server URL Updated');
  }

  void _showEditGarageSheet() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    bool isLoadingGarage = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (isLoadingGarage) {
            final fallbackName = context.read<AuthProvider>().garageName ?? '';
            GarageService.getGarage().then((garage) {
              nameCtrl.text = garage.name;
              addressCtrl.text = garage.address ?? '';
              phoneCtrl.text = garage.phone ?? '';
              emailCtrl.text = garage.email ?? '';
              if (ctx.mounted) {
                setSheetState(() => isLoadingGarage = false);
              }
            }).catchError((e) {
              // Fallback to authProvider garage name
              nameCtrl.text = fallbackName;
              if (ctx.mounted) {
                setSheetState(() => isLoadingGarage = false);
              }
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Garage Profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isLoadingGarage)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Garage Name *',
                        hintText: 'e.g. Shree Auto Garage',
                        prefixIcon: Icon(Icons.store, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g. +91 9876543210',
                        prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'e.g. contact@garage.com',
                        prefixIcon: Icon(Icons.email, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        hintText: 'e.g. Shop 4, Station Road, Pune',
                        prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                                    address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                    phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                    email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                  );

                                  await authProvider.updateGarageName(updated.name);

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  Fluttertoast.showToast(msg: 'Garage details updated successfully!');
                                } catch (e) {
                                  Fluttertoast.showToast(
                                    msg: 'Failed to update: ${e.toString().replaceFirst('Exception: ', '')}',
                                  );
                                } finally {
                                  if (ctx.mounted) setSheetState(() => isSaving = false);
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Save Garage Details',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      nameCtrl.dispose();
      addressCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
    });
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
              onTap: _showEditGarageSheet,
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
