import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/module_api_client.dart';

class ModuleData {
  final int id;
  final String name;
  final String displayName;
  final String? description;
  final String? icon;
  final String? iconPath;
  final String? websiteUrl;
  final String? moduleUrl;
  final String? version;
  final List<String>? permissions;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final String? category;
  final String? developerName;
  final String? developerUrl;
  final int installCount;
  final bool canUpdatePassword;
  final bool isLinked;
  final String? moduleUid;
  final String? linkedAt;
  final List<String>? requiredFields;
  final List<String>? screenshots;
  final bool sslValid;
  final bool urlLoads;
  final String? lastPreflightStatus;
  final String? reviewStatus;
  final String? reviewNotes;

  bool get isMiniApp => moduleUrl != null && moduleUrl!.isNotEmpty;

  ModuleData({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    this.iconPath,
    this.websiteUrl,
    this.moduleUrl,
    this.version,
    this.permissions,
    this.isActive = false,
    this.isFeatured = false,
    this.sortOrder = 0,
    this.category,
    this.developerName,
    this.developerUrl,
    this.installCount = 0,
    this.canUpdatePassword = false,
    this.isLinked = false,
    this.moduleUid,
    this.linkedAt,
    this.requiredFields,
    this.screenshots,
    this.sslValid = false,
    this.urlLoads = false,
    this.lastPreflightStatus,
    this.reviewStatus,
    this.reviewNotes,
  });

  factory ModuleData.fromJson(Map<String, dynamic> json) {
    return ModuleData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      iconPath: json['icon_path'],
      websiteUrl: json['website_url'],
      moduleUrl: json['module_url'],
      version: json['version'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : null,
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      category: json['category'],
      developerName: json['developer_name'],
      developerUrl: json['developer_url'],
      installCount: json['install_count'] ?? 0,
      canUpdatePassword: json['can_update_password'] ?? false,
      isLinked: json['is_linked'] ?? false,
      moduleUid: json['module_uid'],
      linkedAt: json['linked_at'],
      requiredFields: json['required_fields'] != null
          ? List<String>.from(json['required_fields'])
          : null,
      screenshots: json['screenshots'] != null
          ? List<String>.from(json['screenshots'])
          : null,
      sslValid: json['ssl_valid'] ?? false,
      urlLoads: json['url_loads'] ?? false,
      lastPreflightStatus: json['last_preflight_status'],
      reviewStatus: json['review_status'],
      reviewNotes: json['review_notes'],
    );
  }
}

class EmailCheckResult {
  final String module;
  final String displayName;
  final bool exists;
  final String? moduleUid;
  final String? name;

  EmailCheckResult({
    required this.module,
    required this.displayName,
    required this.exists,
    this.moduleUid,
    this.name,
  });

  factory EmailCheckResult.fromJson(Map<String, dynamic> json) {
    return EmailCheckResult(
      module: json['module'] ?? '',
      displayName: json['display_name'] ?? '',
      exists: json['exists'] ?? false,
      moduleUid: json['module_uid'],
      name: json['name'],
    );
  }
}

enum ModuleState { initial, loading, loaded, error }

class ModuleProvider extends ChangeNotifier {
  final ModuleApiClient _api;

  ModuleState _state = ModuleState.initial;
  List<ModuleData> _modules = [];
  List<EmailCheckResult> _emailCheckResults = [];
  String? _errorMessage;

  ModuleState get state => _state;
  List<ModuleData> get modules => _modules;
  List<EmailCheckResult> get emailCheckResults => _emailCheckResults;
  String? get errorMessage => _errorMessage;

  List<ModuleData> get linkedModules =>
      _modules.where((m) => m.isLinked).toList();

  List<ModuleData> get unlinkedModules =>
      _modules.where((m) => !m.isLinked).toList();

  bool get hasCompletedOnboarding => linkedModules.isNotEmpty;

  ModuleProvider({ModuleApiClient? api}) : _api = api ?? ModuleApiClient();

  // ── Load all modules ──────────────────────────────────────────────
  Future<void> loadModules() async {
    // Refresh without blanking the UI: keep the last known list on screen
    // while fetching, only show a loading state when there's nothing yet.
    final hasData = _modules.isNotEmpty;
    if (!hasData) {
      _state = ModuleState.loading;
      notifyListeners();
    }

    try {
      final response = await _api.getModules();
      if (response['success'] == true) {
        final data = response['data']['modules'] as List<dynamic>? ?? [];
        if (data.isEmpty && _modules.isEmpty) {
          // Backend returned nothing (e.g. unseeded DB) — fall back to
          // the built-in catalogue so Bus + Market are always visible.
          _modules = _fallbackModules();
        } else if (data.isNotEmpty) {
          _modules = data.map((m) => ModuleData.fromJson(m)).toList();
          _modules.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }
        _state = ModuleState.loaded;
      } else {
        _errorMessage = response['message'] ?? 'Failed to load modules';
        if (_modules.isEmpty) {
          _modules = _fallbackModules();
          _state = ModuleState.loaded;
        }
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      // Never leave Services/Home completely empty on network/auth errors.
      if (_modules.isEmpty) {
        _modules = _fallbackModules();
        _state = ModuleState.loaded;
      }
    }
    notifyListeners();
  }

  /// Built-in catalogue used when the backend is unreachable or returns
  /// an empty list. Bus + Market are active and open directly; SSO
  /// auto-link fills in the link status once the backend is healthy.
  List<ModuleData> _fallbackModules() {
    return [
      ModuleData(
        id: 1,
        name: 'bus',
        displayName: 'Bus',
        description:
            'Book interstate and intercity bus trips across Nigeria. Compare operators, pick your seat, and pay securely.',
        icon: 'directions_bus_rounded',
        websiteUrl: 'https://bus.opoobo.com',
        isActive: true,
        sortOrder: 0,
      ),
      ModuleData(
        id: 2,
        name: 'market',
        displayName: 'Market',
        description:
            'Buy and sell everything from trusted vendors. Discover deals, order delivery, and pay securely.',
        icon: 'shopping_cart_rounded',
        websiteUrl: 'https://opoobo.market',
        isActive: true,
        sortOrder: 1,
      ),
    ];
  }

  // ── Clear all state (on logout / user switch) ────────────────────
  void clear() {
    _modules = [];
    _emailCheckResults = [];
    _errorMessage = null;
    _state = ModuleState.initial;
    notifyListeners();
  }

  // ── Check email across modules ────────────────────────────────────
  Future<List<EmailCheckResult>> checkEmail({required String email}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.checkEmail(email: email);
      if (response['success'] == true) {
        final results = response['data']['results'] as List<dynamic>? ?? [];
        _emailCheckResults = results
            .map((r) => EmailCheckResult.fromJson(r))
            .toList();
        notifyListeners();
        return _emailCheckResults;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    }
    notifyListeners();
    return [];
  }

  // ── Link existing module account ──────────────────────────────────
  Future<bool> linkModule({
    required String moduleName,
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.linkModule(
        moduleName: moduleName,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        await loadModules(); // Refresh module list
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to link account';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Create new module account ─────────────────────────────────────
  Future<bool> createModuleAccount({
    required String moduleName,
    required Map<String, dynamic> extraFields,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.createModuleAccount(
        moduleName: moduleName,
        extraFields: extraFields,
      );

      if (response['success'] == true) {
        await loadModules(); // Refresh module list
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to create account';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Unlink module ─────────────────────────────────────────────────
  Future<bool> unlinkModule({required String moduleName}) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.unlinkModule(moduleName: moduleName);
      if (response['success'] == true) {
        await loadModules(); // Refresh module list
        return true;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    }
    notifyListeners();
    return false;
  }

  // ── Update password on module ─────────────────────────────────────
  Future<bool> updateModulePassword({
    required String moduleName,
    required String newPassword,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.updateModulePassword(
        moduleName: moduleName,
        newPassword: newPassword,
      );
      if (response['success'] == true) {
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to update password';
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    }
    notifyListeners();
    return false;
  }

  // ── Check if specific module is linked ────────────────────────────
  bool isModuleLinked(String moduleName) {
    final module = _modules.firstWhere(
      (m) => m.name == moduleName,
      orElse: () => ModuleData(id: 0, name: '', displayName: ''),
    );
    return module.isLinked;
  }

  // ── Get module UID ────────────────────────────────────────────────
  String? getModuleUid(String moduleName) {
    final module = _modules.firstWhere(
      (m) => m.name == moduleName,
      orElse: () => ModuleData(id: 0, name: '', displayName: ''),
    );
    return module.moduleUid;
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data;
        if (data['message'] != null) return data['message'];
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your connection.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
