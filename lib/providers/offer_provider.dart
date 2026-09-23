import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/offers.dart';

class OfferProvider extends ChangeNotifier {
  final ApiClient _api;

  OfferProvider({ApiClient? api}) : _api = api ?? ApiClient();

  List<DailyDeal> _deals = [];
  RewardsSummary? _rewards;
  bool _loadingDeals = false;
  bool _loadingRewards = false;
  String? _dealsError;
  String? _rewardsError;

  List<DailyDeal> get deals => _deals;
  RewardsSummary? get rewards => _rewards;
  bool get loadingDeals => _loadingDeals;
  bool get loadingRewards => _loadingRewards;
  String? get dealsError => _dealsError;
  String? get rewardsError => _rewardsError;

  Future<void> load() async {
    await Future.wait([loadDeals(), loadRewards()]);
  }

  Future<void> loadDeals() async {
    _loadingDeals = true;
    _dealsError = null;
    notifyListeners();
    try {
      final response = await _api.getDeals();
      final data = response['data'];
      if (response['success'] == true && data is List) {
        _deals = data
            .whereType<Map>()
            .map((item) => DailyDeal.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _deals = [];
        _dealsError = (response['message'] ?? 'Deals are unavailable').toString();
      }
    } catch (e) {
      _deals = [];
      _dealsError = 'Deals are unavailable';
    } finally {
      _loadingDeals = false;
      notifyListeners();
    }
  }

  Future<void> loadRewards() async {
    _loadingRewards = true;
    _rewardsError = null;
    notifyListeners();
    try {
      final response = await _api.getRewards();
      final data = response['data'];
      if (response['success'] == true && data is Map) {
        _rewards = RewardsSummary.fromJson(Map<String, dynamic>.from(data));
      } else {
        _rewards = null;
        _rewardsError =
            (response['message'] ?? 'Rewards are unavailable').toString();
      }
    } catch (e) {
      _rewards = null;
      _rewardsError = 'Rewards are unavailable';
    } finally {
      _loadingRewards = false;
      notifyListeners();
    }
  }
}
