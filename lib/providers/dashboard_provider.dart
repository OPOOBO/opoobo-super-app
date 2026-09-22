import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/bus/booking.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _api;

  DashboardProvider({ApiClient? api}) : _api = api ?? ApiClient();

  int _linkedModulesCount = 0;
  double _walletBalance = 0;
  int _rewardPoints = 0;
  String _membershipTier = 'basic';
  String? _memberSince;
  bool _isLoading = false;
  String? _error;

  int get linkedModulesCount => _linkedModulesCount;
  double get walletBalance => _walletBalance;
  int get rewardPoints => _rewardPoints;
  String get membershipTier => _membershipTier;
  String? get memberSince => _memberSince;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int monthlySpend(List<Booking> bookings) {
    final now = DateTime.now();
    final total = bookings
        .where((b) {
          if (b.bookDate.isEmpty) return false;
          try {
            final date = DateTime.parse(b.bookDate);
            return date.year == now.year && date.month == now.month;
          } catch (_) {
            return false;
          }
        })
        .fold<double>(
          0,
          (sum, b) => sum + (double.tryParse(b.ticketPrice) ?? 0),
        );
    return total.round();
  }

  int activeOrders(List<Booking> bookings) {
    return bookings.where((b) => b.isPending).length;
  }

  String formatCurrency(int amount) {
    if (amount >= 1000000) {
      return '\u20a6${(amount / 1000000).toStringAsFixed(1)}m';
    } else if (amount >= 1000) {
      return '\u20a6${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\u20a6${amount.toString()}';
  }

  String formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}k';
    }
    return points.toString();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.getStats();
      final data = response['data'] ?? {};
      _linkedModulesCount = data['linked_modules_count'] ?? 0;
      _walletBalance = (data['wallet_balance'] ?? 0).toDouble();
      _rewardPoints = data['reward_points'] ?? 0;
      _membershipTier = data['membership_tier'] ?? 'basic';
      _memberSince = data['member_since'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
