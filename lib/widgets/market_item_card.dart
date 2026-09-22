import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/market_service.dart';

String marketTimeAgo(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt = DateTime.parse(raw);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  } catch (_) {
    return '';
  }
}

/// Classifieds-style item card shared by Marketplace and Saved screens.
/// The heart writes to the market `favourites` table, so it syncs with
/// the main market app automatically (same market user).
class MarketItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool favourited;
  final void Function(int id, bool favourited)? onFavouriteChanged;
  final VoidCallback? onTap;

  const MarketItemCard({
    super.key,
    required this.item,
    this.favourited = false,
    this.onFavouriteChanged,
    this.onTap,
  });

  @override
  State<MarketItemCard> createState() => _MarketItemCardState();
}

class _MarketItemCardState extends State<MarketItemCard> {
  late bool _fav;
  bool _favBusy = false;

  @override
  void initState() {
    super.initState();
    _fav = widget.favourited;
  }

  @override
  void didUpdateWidget(MarketItemCard old) {
    super.didUpdateWidget(old);
    if (old.favourited != widget.favourited && !_favBusy) {
      _fav = widget.favourited;
    }
  }

  Future<void> _toggleFav() async {
    if (_favBusy) return;
    final id = (widget.item['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() {
      _favBusy = true;
      _fav = !_fav;
    });
    try {
      final res = await MarketService().toggleFavourite({'item_id': id});
      if (!mounted) return;
      if (!marketSuccess(res)) {
        setState(() => _fav = !_fav);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res?['message']?.toString() ?? 'Could not update favourites.',
            ),
          ),
        );
      } else {
        widget.onFavouriteChanged?.call(id, _fav);
      }
    } catch (_) {
      if (mounted) setState(() => _fav = !_fav);
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = (item['formatted_price'] ?? item['price'] ?? '').toString();
    final title = (item['translated_name'] ?? item['name'] ?? '').toString();
    final image = (item['image'] ?? '').toString();
    final area = (item['area'] is Map)
        ? ((item['area']['name'] ?? '').toString())
        : '';
    final time = marketTimeAgo(item['created_at']?.toString());
    final featured =
        item['featured_items'] is List &&
        (item['featured_items'] as List).isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_outlined),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 40),
                          ),
                  ),
                  if (featured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Featured',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleFav,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: _fav ? Colors.redAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          [area, time].where((s) => s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
