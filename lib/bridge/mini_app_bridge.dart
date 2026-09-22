import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../core/sso_service.dart';
import 'bridge_js.dart';

class MiniAppBridge {
  /// Injects the full opoobo SDK into the WebView.
  static Future<void> inject({
    required InAppWebViewController controller,
    required String moduleName,
    required String moduleVersion,
    required String theme,
  }) async {
    try {
      final sso = SsoService();
      final token = await sso.getAccessToken();
      final profile = await sso.getStoredProfile() ?? {};

      // Escape strings for JS
      final safeToken = _escapeJs(token ?? '');
      final safeName = _escapeJs(moduleName);
      final safeVersion = _escapeJs(moduleVersion);
      final safeTheme = _escapeJs(theme);
      final safeProfile = _escapeJs(_jsonEncode(profile));

      await controller.evaluateJavascript(source: '''
        (function() {
          $miniAppBridgeJs

          window.opoobo._setToken("$safeToken");
          window.opoobo._setModuleInfo("$safeName", "$safeVersion");
          window.opoobo._setTheme("$safeTheme");
          window.opoobo._setUserProfile(JSON.parse("$safeProfile"));
        })();
      ''');
    } catch (e) {
      debugPrint('[MiniAppBridge] Injection failed: $e');
    }
  }

  /// Updates just the theme without full re-injection.
  static Future<void> injectTheme({
    required InAppWebViewController controller,
    required String theme,
  }) async {
    try {
      final safeTheme = _escapeJs(theme);
      await controller.evaluateJavascript(source: '''
        (function() {
          if (window.opoobo && window.opoobo._setTheme) {
            window.opoobo._setTheme("$safeTheme");
            window.dispatchEvent(new CustomEvent('opoobo:themeChanged', {
              detail: { theme: "$safeTheme" }
            }));
          }
        })();
      ''');
    } catch (e) {
      debugPrint('[MiniAppBridge] Theme injection failed: $e');
    }
  }

  /// Removes the bridge (on domain change away from approved domain).
  static Future<void> remove({
    required InAppWebViewController controller,
  }) async {
    try {
      await controller.evaluateJavascript(source: '''
        (function() {
          delete window.opoobo;
        })();
      ''');
    } catch (_) {}
  }

  /// Handles postMessage calls from mini-app.
  static Future<void> handleMessage(
    Map<String, dynamic> message,
    BuildContext context,
  ) async {
    final action = message['action'] as String?;
    if (action == null) return;

    switch (action) {
      case 'requestBack':
        if (context.mounted) Navigator.of(context).pop();
        break;

      case 'showToast':
        final msg = message['data']?['message'] as String? ?? '';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
          );
        }
        break;

      case 'getWalletBalance':
      case 'getSavedAddresses':
      case 'getPaymentMethods':
        // Read-only — return empty for now; full implementation would
        // call the backend API and return the result via postMessage.
        break;
    }
  }

  static String _escapeJs(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  static String _jsonEncode(Map<String, dynamic> map) {
    // Simple JSON encode without dart:convert dependency in this context
    if (map.isEmpty) return '{}';
    final entries = map.entries.map((e) {
      final val = e.value;
      final escaped = val.toString().replaceAll('"', '\\"');
      return '"${e.key}":"$escaped"';
    }).join(',');
    return '{$entries}';
  }
}
