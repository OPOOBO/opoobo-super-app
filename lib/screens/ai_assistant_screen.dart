import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/module_provider.dart';
import '../services/ai_assistant_service.dart';
import '../theme/app_colors.dart';
import '../utils/navigation.dart';
import '../widgets/screen_header.dart';
import 'bus_module_screen.dart';
import 'marketplace_screen.dart';
import 'mini_app_screen.dart';
import 'search_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatBubble {
  final String role;
  final String content;
  final List<AiChatAction> actions;

  const _ChatBubble({
    required this.role,
    required this.content,
    this.actions = const [],
  });
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final AiAssistantService _service = AiAssistantService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatBubble> _messages = [
    const _ChatBubble(
      role: 'assistant',
      content:
          'Hi — I\'m Ask OPOOBO. Ask me to find a service, open Bus or Market, or answer questions about the app.',
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatBubble(role: 'user', content: text));
      _sending = true;
    });
    _ctrl.clear();
    _scrollToEnd();

    try {
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .map((m) => AiChatMessage(role: m.role, content: m.content))
          .toList();
      final res = await _service.chat(history);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubble(
            role: 'assistant',
            content: res.reply.isEmpty
                ? 'I couldn\'t generate a reply. Try again.'
                : res.reply,
            actions: res.actions,
          ),
        );
      });
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatBubble(
            role: 'assistant',
            content:
                'I couldn\'t reach the assistant right now. Check your connection and try again.',
          ),
        );
      });
      _scrollToEnd();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleAction(AiChatAction action) {
    switch (action.type) {
      case 'open_search':
        NavigationHelper.push(
          context,
          SearchScreen(initialQuery: action.query),
        );
        return;
      case 'open_module':
        final name = action.moduleName;
        if (name == null || name.isEmpty) return;
        final modules = context.read<ModuleProvider>().modules;
        ModuleData? module;
        for (final m in modules) {
          if (m.name == name) {
            module = m;
            break;
          }
        }
        if (module == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Service "$name" is not available.')),
          );
          return;
        }
        _openModule(module);
        return;
      default:
        return;
    }
  }

  void _openModule(ModuleData module) {
    if (module.isMiniApp) {
      NavigationHelper.push(context, MiniAppScreen(module: module));
      return;
    }
    if (module.name == 'bus') {
      NavigationHelper.push(context, const BusModuleScreen());
      return;
    }
    if (module.name == 'market') {
      if (!module.isActive) {
        _showComingSoon(module);
        return;
      }
      NavigationHelper.push(context, const MarketplaceScreen());
      return;
    }
    if (!module.isActive) {
      _showComingSoon(module);
    }
  }

  void _showComingSoon(ModuleData module) {
    final url = module.websiteUrl ?? 'https://opoobo.com';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${module.displayName} is coming soon'),
        content: Text('Visit us at $url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(
            title: 'Ask OPOOBO',
            subtitle: 'Find services & get answers',
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_sending && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                final mine = message.role == 'user';
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    child: Column(
                      crossAxisAlignment: mine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: mine ? AppColors.gradientPrimary : null,
                            color: mine
                                ? null
                                : (isDark
                                      ? AppColors.darkSurface
                                      : const Color(0xFFF1F1F1)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.content,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: mine
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkForeground
                                        : AppColors.foreground),
                            ),
                          ),
                        ),
                        if (message.actions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: message.actions.map((action) {
                              return GestureDetector(
                                onTap: () => _handleAction(action),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    action.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask about a service…',
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
