import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../bridge/mini_app_bridge.dart';
import '../providers/module_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_app_header.dart';

class MiniAppScreen extends StatefulWidget {
  final ModuleData module;

  const MiniAppScreen({super.key, required this.module});

  @override
  State<MiniAppScreen> createState() => _MiniAppScreenState();
}

class _MiniAppScreenState extends State<MiniAppScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  String? _currentUrl;
  bool _bridgeInjected = false;
  String? _approvedOrigin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _approvedOrigin = _extractOrigin(widget.module.moduleUrl ?? '');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController == null) return;
    if (state == AppLifecycleState.paused) {
      _dispatchEvent('opoobo:appPause');
    } else if (state == AppLifecycleState.resumed) {
      _dispatchEvent('opoobo:appResume');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url =
        widget.module.moduleUrl ??
        widget.module.websiteUrl ??
        'https://opoobo.com';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        appBar: MiniAppHeader(
          moduleName: widget.module.displayName,
          onBack: () async {
            if (_webViewController != null &&
                await _webViewController!.canGoBack()) {
              await _webViewController!.goBack();
            } else {
              if (context.mounted) Navigator.of(context).pop();
            }
          },
          onRefresh: () => _webViewController?.reload(),
          onOpenInBrowser: () => _openInBrowser(),
          onCopyLink: () => _copyLink(),
          onReport: () => _reportApp(),
        ),
        body: Column(
          children: [
            if (_progress > 0 && _progress < 1)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                minHeight: 2,
              ),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(url)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  useWideViewPort: true,
                  loadWithOverviewMode: true,
                  supportZoom: false,
                  transparentBackground: true,
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  useOnLoadResource: true,
                  cacheEnabled: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  _setupMessageHandler(controller);
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _currentUrl = url?.toString();
                    _bridgeInjected = false;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() => _currentUrl = url?.toString());
                  if (!_bridgeInjected) {
                    await _injectBridge(controller);
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100.0);
                },
                onConsoleMessage: (controller, consoleMessage) {
                  debugPrint('[MiniApp] ${consoleMessage.message}');
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri != null) {
                    final scheme = uri.scheme.toLowerCase();
                    if (scheme == 'tel' || scheme == 'sms' || scheme == 'mailto') {
                      return NavigationActionPolicy.ALLOW;
                    }

                    // Block navigation outside approved domain
                    if (_approvedOrigin != null) {
                      final targetOrigin = _extractOrigin(uri.toString());
                      if (targetOrigin != _approvedOrigin) {
                        return NavigationActionPolicy.CANCEL;
                      }
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _injectBridge(InAppWebViewController controller) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _bridgeInjected = true;

    await MiniAppBridge.inject(
      controller: controller,
      moduleName: widget.module.name,
      moduleVersion: widget.module.version ?? '1.0.0',
      theme: isDark ? 'dark' : 'light',
    );
  }

  void _dispatchEvent(String eventName) {
    if (_webViewController == null) return;
    _webViewController!.evaluateJavascript(source: '''
      window.dispatchEvent(new CustomEvent('$eventName'));
    ''');
  }

  void _setupMessageHandler(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: 'opooboBridge',
      callback: (args) {
        if (args.isNotEmpty && args[0] is String) {
          try {
            final data = args[0] as String;
            // Handle postMessage from mini-app
            debugPrint('[MiniAppBridge] Received: $data');
          } catch (e) {
            debugPrint('[MiniAppBridge] Parse error: $e');
          }
        }
      },
    );
  }

  String? _extractOrigin(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (_) {
      return null;
    }
  }

  void _openInBrowser() {
    final url = _currentUrl ?? widget.module.moduleUrl ?? '';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _copyLink() {
    final url = _currentUrl ?? widget.module.moduleUrl ?? '';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  void _reportApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report App'),
        content: const Text('Are you sure you want to report this app? Our team will review it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted. Thank you.')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}
