import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/market_service.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final MarketService _market = MarketService();
  final PageController _pageCtrl = PageController();
  List<dynamic> _reels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    final result = await _market.getReels();
    if (mounted) {
      setState(() {
        _reels = result?['data'] ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _reels.isEmpty
          ? const Center(
              child: Text(
                'No reels yet',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : PageView.builder(
              controller: _pageCtrl,
              scrollDirection: Axis.vertical,
              itemCount: _reels.length,
              itemBuilder: (ctx, i) => _ReelItem(reel: _reels[i]),
            ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  final dynamic reel;
  const _ReelItem({required this.reel});

  @override
  Widget build(BuildContext context) {
    final title = reel['title'] ?? reel['name'] ?? '';
    final user = reel['user']?['name'] ?? 'User';
    final likes = reel['likes_count'] ?? 0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video placeholder
        Container(color: const Color(0xFF1A1A1A)),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),
        // Info
        Positioned(
          bottom: 24,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@$user',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        // Actions
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _ActionBtn(
                icon: Icons.favorite_rounded,
                count: '$likes',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                icon: Icons.chat_bubble_rounded,
                count: '0',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              _ActionBtn(
                icon: Icons.share_rounded,
                count: 'Share',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String count;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
