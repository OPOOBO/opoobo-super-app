import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/market_service.dart';
import 'market_chat_thread_screen.dart';

/// Buyer-side conversations (one row per item offer).
class MarketChatListScreen extends StatefulWidget {
  const MarketChatListScreen({super.key});

  @override
  State<MarketChatListScreen> createState() => _MarketChatListScreenState();
}

class _MarketChatListScreenState extends State<MarketChatListScreen> {
  final MarketService _market = MarketService();
  List<dynamic> _chats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _market.getChatList();
      if (!mounted) return;
      setState(() {
        _chats = _parseList(res);
        if (_chats.isEmpty && res == null) {
          _error = 'Could not load chats. Check your connection.';
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Failed to load chats.';
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

  int? _myId(Map<String, dynamic> offer) {
    final b = offer['buyer'];
    if (b is Map && b['id'] != null) return (b['id'] as num).toInt();
    final bid = offer['buyer_id'];
    return bid == null ? null : (bid as num).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.sora(fontWeight: FontWeight.w800),
        ),
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _chats.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _chats.isEmpty
          ? RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('No conversations yet.')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: _chats.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final offer = Map<String, dynamic>.from(_chats[i] as Map);
                  final item = offer['item'] is Map
                      ? Map<String, dynamic>.from(offer['item'])
                      : <String, dynamic>{};
                  final seller = offer['seller'] is Map
                      ? Map<String, dynamic>.from(offer['seller'])
                      : <String, dynamic>{};
                  final title = (item['name'] ?? '').toString();
                  final sellerName = (seller['name'] ?? 'Seller').toString();
                  final image = (item['image'] ?? '').toString();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      backgroundImage: image.isNotEmpty
                          ? NetworkImage(image)
                          : null,
                      onBackgroundImageError: image.isNotEmpty
                          ? (_, _) {}
                          : null,
                      child: image.isEmpty
                          ? const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      sellerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketChatThreadScreen(
                          offer: offer,
                          myUserId: _myId(offer),
                          itemTitle: title,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
