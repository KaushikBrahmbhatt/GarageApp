import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/job_card_provider.dart';
import 'services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // BUG-16 fix: only bypass SSL in debug mode (e.g. local tunnel)
      // REMOVE this entire override before production release
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => kDebugMode;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
  ApiService.onUnauthorized = () {
    Fluttertoast.showToast(msg: 'Session expired (401). Please log in again.');
  };

  final prefs = await SharedPreferences.getInstance();
  final token  = prefs.getString('token');
  
  final authProvider = AuthProvider();
  // BUG-21 fix: call restoreSession so staffName/garageName are set before routing
  await authProvider.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => JobCardProvider()),
      ],
      child: MyApp(initialToken: token),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Garage App',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.getRouter(initialToken),
      debugShowCheckedModeBanner: false,
    );
  }
}
