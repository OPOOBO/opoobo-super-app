import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/market_service.dart';

/// One conversation: messages under an item offer + send box.
class MarketChatThreadScreen extends StatefulWidget {
  final Map<String, dynamic> offer;
  final int? myUserId;
  final String itemTitle;

  const MarketChatThreadScreen({
    super.key,
    required this.offer,
    required this.myUserId,
    required this.itemTitle,
  });

  @override
  State<MarketChatThreadScreen> createState() => _MarketChatThreadScreenState();
}

class _MarketChatThreadScreenState extends State<MarketChatThreadScreen> {
  final MarketService _market = MarketService();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  int get _offerId => (widget.offer['id'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _market.getChatMessages(offerId: _offerId);
      if (!mounted) return;
      setState(() {
        // Upstream returns newest-first; display oldest-first.
        _messages = _parseList(res).reversed.toList();
        if (_messages.isEmpty && res == null) {
          _error = 'Could not load messages.';
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load messages.';
          _loading = false;
        });
    }
  }

  List<dynamic> _parseList(Map<String, dynamic>? res) {
    if (!marketSuccess(res)) return [];
    final d = res!['data'];
    if (d is List) return d;
    if (d is Map && d['data'] is List) return d['data'];
    return [];
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await _market.sendMessage(offerId: _offerId, message: text);
      if (!mounted) return;
      if (!marketSuccess(res)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res?['message']?.toString() ?? 'Message not sent.'),
          ),
        );
      } else {
        _ctrl.clear();
        await _load();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message not sent. Check connection.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.itemTitle.isNotEmpty ? widget.itemTitle : 'Chat',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.sora(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Text('Say hello to start the conversation.'),
                  )
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = Map<String, dynamic>.from(
                        _messages[_messages.length - 1 - i] as Map,
                      );
                      final mine =
                          widget.myUserId != null &&
                          (m['sender_id'] as num?)?.toInt() == widget.myUserId;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                            (m['message'] ?? '').toString(),
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
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
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
