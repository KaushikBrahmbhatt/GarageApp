import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job_card.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _error = '';

  int todayJobs = 0;
  int inProgress = 0;
  int awaitingConfirmation = 0;
  double todayRevenue = 0.0;
  List<JobCard> todayJobCards = [];

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final data = await _api.get('/dashboard/stats');
      todayJobs = data['today_jobs'] ?? 0;
      inProgress = data['in_progress'] ?? 0;
      awaitingConfirmation = data['awaiting_confirmation'] ?? 0;
      todayRevenue = double.parse((data['today_revenue'] ?? 0).toString());
      if (data['today_job_cards'] != null) {
        todayJobCards = (data['today_job_cards'] as List).map((e) => JobCard.fromJson(e)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
