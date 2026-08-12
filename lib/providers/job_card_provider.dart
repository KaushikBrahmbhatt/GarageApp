import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/job_card.dart';

class JobCardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String _error = '';
  JobCard? currentJobCard;

  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchJobCard(int id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final data = await _api.get('/job-cards/$id');
      currentJobCard = JobCard.fromJson(data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    try {
      await _api.patch('/job-cards/$id/status', {'status': status});
      await fetchJobCard(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> createJobCard(Map<String, dynamic> data) async {
    try {
      await _api.post('/job-cards', data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
