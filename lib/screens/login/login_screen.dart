import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@garage.com');
  final _passCtrl  = TextEditingController(text: 'garage@123');

  void _login() async {
    final provider = context.read<AuthProvider>();
    final success = await provider.login(_emailCtrl.text, _passCtrl.text);
    if (success) {
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.kError,
            content: Text('Login failed: ${provider.error}'),
          ),
        );
      }
    }
  }

  void _showServerUrlDialog() async {
    final currentUrl = await ApiConfig.getBaseUrl();
    final urlCtrl = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.kCard,
        title: const Text('Backend API URL', style: TextStyle(color: AppTheme.kTextPrimary)),
        content: TextField(
          controller: urlCtrl,
          style: const TextStyle(color: AppTheme.kTextPrimary),
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'https://your-codespace-url/api',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.kTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimary),
            onPressed: () async {
              await ApiConfig.setBaseUrl(urlCtrl.text.trim());
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('API Server URL updated!')),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.kPrimary),
            tooltip: 'Server Settings',
            onPressed: _showServerUrlDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: AppTheme.kCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_circle, size: 64, color: AppTheme.kPrimary),
                  const SizedBox(height: 16),
                  Text('Kaushik Garage', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.kPrimary, fontWeight: FontWeight.bold)),
                  const Text('Garage Management System', style: TextStyle(color: AppTheme.kTextMuted)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: AppTheme.kTextPrimary),
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.kTextPrimary),
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: provider.isLoading ? null : _login,
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.dns, size: 16, color: AppTheme.kTextMuted),
                    label: const Text('Configure Server URL', style: TextStyle(color: AppTheme.kTextMuted, fontSize: 12)),
                    onPressed: _showServerUrlDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
