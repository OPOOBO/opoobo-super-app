import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/market_service.dart';
import '../widgets/market_item_card.dart';
import 'market_chat_thread_screen.dart';

/// Full item view: gallery, price, specs, seller card and
/// Chat / Call / Make-offer actions.
class MarketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const MarketDetailScreen({super.key, required this.item});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  final MarketService _market = MarketService();
  late Map<String, dynamic> _item;
  bool _loading = false;
  bool _acting = false;
  int _photoIndex = 0;
  final PageController _photos = PageController();

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
    _refresh();
  }

  @override
  void dispose() {
    _photos.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final key = _item['slug'] ?? _item['id'];
    if (key == null) return;
    setState(() => _loading = true);
    try {
      final res = await _market.getItemDetail(key.toString());
      if (!mounted) return;
      final fresh = _first(res);
      if (fresh != null) {
        if (!mounted) return;
        setState(() => _item = fresh);
        _loadRelated();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _first(Map<String, dynamic>? res) {
    if (res == null) return null;
    final d = res['data'];
    if (d is Map && d['data'] is List && (d['data'] as List).isNotEmpty) {
      return Map<String, dynamic>.from(d['data'].first);
    }
    if (d is List && d.isNotEmpty) {
      return Map<String, dynamic>.from(d.first);
    }
    return null;
  }

  List<String> get _photosList {
    final g = _item['gallery_images'];
    if (g is List && g.isNotEmpty) {
      return g
          .map((e) => (e is Map ? (e['image'] ?? '') : '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final single = (_item['image'] ?? '').toString();
    return single.isNotEmpty ? [single] : [];
  }

  Map<String, dynamic> get _seller {
    final u = _item['user'];
    return u is Map ? Map<String, dynamic>.from(u) : {};
  }

  /// Own listings (posted via the main app under the same email) can't be
  /// chatted/offered on — upstream answers those with 'No Item Found'.
  bool get _isOwn {
    try {
      final sellerEmail = (_seller['email'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (sellerEmail.isEmpty) return false;
      final myEmail = context
          .read<AuthProvider>()
          .displayEmail
          .trim()
          .toLowerCase();
      return myEmail.isNotEmpty && myEmail == sellerEmail;
    } catch (_) {
      return false;
    }
  }

  /// Translate upstream errors into buyer-friendly wording.
  String _friendlyError(String? message, String fallback) {
    if (message != null && message.contains('No Item Found')) {
      return 'This item is no longer available.';
    }
    return message ?? fallback;
  }

  Future<void> _openChat() async {
    final id = (_item['id'] as num?)?.toInt();
    if (id == null) return;
    if (_isOwn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing.')),
      );
      return;
    }
    setState(() => _acting = true);
    try {
      final res = await _market.makeOffer(itemId: id);
      if (!mounted) return;
      if (res == null || !marketSuccess(res)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(
                res?['message']?.toString(),
                'Could not start chat.',
              ),
            ),
          ),
        );
        return;
      }
      final offer = _offerOf(res);
      if (offer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This item is no longer available.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketChatThreadScreen(
            offer: offer,
            myUserId: _myId(offer),
            itemTitle: _title(),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start chat. Check connection.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Map<String, dynamic>? _offerOf(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map) return Map<String, dynamic>.from(d);
    return null;
  }

  int? _myId(Map<String, dynamic> offer) {
    final b = offer['buyer'];
    if (b is Map && b['id'] != null) return (b['id'] as num).toInt();
    final bid = offer['buyer_id'];
    return bid == null ? null : (bid as num).toInt();
  }

  Future<void> _callSeller() async {
    final mobile = (_seller['mobile'] ?? '').toString();
    if (mobile.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller contact is not available.')),
      );
      return;
    }
    // Keep only dialable chars — spaces/dashes break tel: links.
    final code = (_seller['country_code'] ?? '').toString().replaceAll(
      RegExp(r'[^+\d]'),
      '',
    );
    final number = mobile.replaceAll(RegExp(r'[^+\d]'), '');
    final display = '$code$number';
    final uri = Uri.parse('tel:$display');
    try {
      // No canLaunchUrl gate: on Android 11+ it needs a manifest <queries>
      // entry and falsely reports false; the dialer intent itself works.
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw StateError('dialer unavailable');
    } catch (_) {
      if (!mounted) return;
      // Actionable fallback: number on clipboard, user pastes into dialer.
      await Clipboard.setData(ClipboardData(text: display));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dialer unavailable — number copied: $display')),
      );
    }
  }

  Future<void> _makeOffer() async {
    final id = (_item['id'] as num?)?.toInt();
    if (id == null) return;
    if (_isOwn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing.')),
      );
      return;
    }
    final ctrl = TextEditingController();
    final amount = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Make an offer'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Your price',
            prefixText: '₦ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (amount == null || amount.isEmpty) return;
    setState(() => _acting = true);
    try {
      final res = await _market.makeOffer(itemId: id, amount: amount);
      if (!mounted) return;
      if (res == null || !marketSuccess(res)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(
                res?['message']?.toString(),
                'Could not send offer.',
              ),
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Offer sent.')),
      );
      final offer = _offerOf(res);
      if (offer != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarketChatThreadScreen(
              offer: offer,
              myUserId: _myId(offer),
              itemTitle: _title(),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not send offer.')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  String _title() =>
      (_item['translated_name'] ?? _item['name'] ?? '').toString();

  List<dynamic> _related = [];
  bool _loadingRelated = false;

  Future<void> _loadRelated() async {
    final cat = _item['category'];
    final catId = cat is Map ? (cat['id'] as num?)?.toInt() : null;
    final myId = (_item['id'] as num?)?.toInt();
    if (catId == null || myId == null) return;
    setState(() => _loadingRelated = true);
    try {
      final res = await _market.getItems(
        filters: {
          'category_id': catId,
          'excluded_item_id': myId,
          'limit': 10,
          'status': 'approved',
        },
      );
      if (!mounted) return;
      final d = res?['data'];
      List<dynamic> list = [];
      if (d is Map && d['data'] is List) list = d['data'];
      if (d is List) list = d;
      setState(() {
        _related = list.where((e) {
          if (e is! Map) return false;
          return (e['id'] as num?)?.toInt() != myId;
        }).toList();
        _loadingRelated = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRelated = false);
    }
  }

  Future<void> _shareItem() async {
    final price = (_item['formatted_price'] ?? _item['price'] ?? '').toString();
    final text =
        '${_title()}${price.isNotEmpty ? ' — $price' : ''} on OPOOBO Market';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item details copied — paste anywhere to share.'),
      ),
    );
  }

  void _menuAction(String value) {
    if (value == 'review') {
      _reviewSheet();
    } else if (value == 'report') {
      _reportSheet();
    }
  }

  void _openGallery() {
    final photos = _photosList;
    if (photos.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenGallery(photos: photos, initial: _photoIndex),
    );
  }

  Future<void> _reviewSheet() async {
    if (_isOwn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own listing.')),
      );
      return;
    }
    final id = (_item['id'] as num?)?.toInt();
    if (id == null) return;
    double rating = 5;
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rate this seller',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Only buyers of sold items can review. The platform confirms eligibility.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setSheet(() => rating = i + 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < rating
                            ? Icons.star_outlined
                            : Icons.star_border_outlined,
                        size: 36,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a review (optional)...',
                  filled: true,
                  fillColor: AppColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Submit review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final res = await _market.submitReview(
        itemId: id,
        rating: rating,
        review: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message']?.toString() ?? 'Review submitted.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit review.')),
        );
      }
    }
  }

  Future<void> _reportSheet() async {
    final id = (_item['id'] as num?)?.toInt();
    if (id == null) return;
    List<dynamic> reasons = [];
    try {
      final res = await _market.getReportReasons();
      final d = res?['data'];
      if (d is Map && d['data'] is List) {
        reasons = d['data'];
      } else if (d is List) {
        reasons = d;
      }
    } catch (_) {}
    if (!mounted) return;
    int? selected;
    final otherCtrl = TextEditingController();
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report listing',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Why are you reporting this item?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...reasons.map((r) {
                final m = Map<String, dynamic>.from(r as Map);
                final rid = (m['id'] as num?)?.toInt();
                final label = (m['reason'] ?? m['name'] ?? m['title'] ?? '')
                    .toString();
                return RadioListTile<int>(
                  value: rid ?? -1,
                  groupValue: selected,
                  onChanged: (v) => setSheet(() => selected = v),
                  title: Text(
                    label,
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
              TextField(
                controller: otherCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'More details (optional)...',
                  filled: true,
                  fillColor: AppColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Submit report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (done != true || !mounted) return;
    if (selected == null && otherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a reason or describe the issue.')),
      );
      return;
    }
    try {
      final res = await _market.reportItem(
        itemId: id,
        reasonId: selected == null || selected == -1 ? null : selected,
        message: otherCtrl.text.trim().isEmpty ? null : otherCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['message']?.toString() ?? 'Report submitted.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final photos = _photosList;
    final price = (_item['formatted_price'] ?? _item['price'] ?? '').toString();
    final area = (_item['area'] is Map)
        ? ((_item['area']['name'] ?? '').toString())
        : '';
    final category = (_item['category'] is Map)
        ? ((_item['category']['name'] ?? '').toString())
        : '';
    final desc = (_item['translated_description'] ?? _item['description'] ?? '')
        .toString();
    final sellerName = (_seller['name'] ?? 'Seller').toString();
    final sellerAvatar = (_seller['profile'] ?? '').toString();
    final verified =
        _seller['is_verified'] == true || _seller['is_verified'] == 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : AppColors.background,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: _shareItem,
                ),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: _menuAction,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'review', child: Text('Rate seller')),
                    PopupMenuItem(
                      value: 'report',
                      child: Text('Report listing'),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: photos.isEmpty
                    ? Container(
                        color: AppColors.muted,
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 64),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: _openGallery,
                            child: PageView.builder(
                              controller: _photos,
                              itemCount: photos.length,
                              onPageChanged: (i) =>
                                  setState(() => _photoIndex = i),
                              itemBuilder: (_, i) => Image.network(
                                photos[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.muted,
                                  child: const Center(
                                    child: Icon(Icons.image_outlined, size: 64),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (photos.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  photos.length,
                                  (i) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == _photoIndex
                                          ? Colors.white
                                          : Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _title(),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              area,
                              category,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Description', isDark),
                    const SizedBox(height: 6),
                    Text(
                      desc.isNotEmpty ? desc : 'No description provided.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Details', isDark),
                    const SizedBox(height: 8),
                    _specsGrid(isDark),
                    const SizedBox(height: 16),
                    _sectionTitle('Seller', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            backgroundImage: sellerAvatar.isNotEmpty
                                ? NetworkImage(sellerAvatar)
                                : null,
                            onBackgroundImageError: sellerAvatar.isNotEmpty
                                ? (_, _) {}
                                : null,
                            child: sellerAvatar.isEmpty
                                ? Text(
                                    sellerName.isNotEmpty
                                        ? sellerName[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        sellerName,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (verified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_outlined,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Market seller',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                if ((_seller['mobile'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${(_seller['country_code'] ?? '').toString()} ${(_seller['mobile'] ?? '').toString()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Safety tips', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          _SafetyTip(text: 'Meet in a public, well-lit place.'),
                          _SafetyTip(text: 'Inspect the item before paying.'),
                          _SafetyTip(
                            text: 'Never pay in advance for delivery.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_related.isNotEmpty || _loadingRelated) ...[
                      _sectionTitle('Related items', isDark),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 236,
                        child: _loadingRelated && _related.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _related.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (ctx, i) {
                                  final m = Map<String, dynamic>.from(
                                    _related[i] as Map,
                                  );
                                  return SizedBox(
                                    width: 160,
                                    child: MarketItemCard(
                                      item: m,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MarketDetailScreen(item: m),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
        child: _isOwn
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'This is your own listing',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _acting ? null : _openChat,
                      icon: _acting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.chat_bubble_outline_outlined,
                              size: 18,
                            ),
                      label: const Text('Chat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _callSeller,
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: _acting ? null : _makeOffer,
                      child: const Text('Make offer'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _specsGrid(bool isDark) {
    final specs = <Map<String, String>>[];
    final category = (_item['category'] is Map)
        ? ((_item['category']['name'] ?? '').toString())
        : '';
    if (category.isNotEmpty)
      specs.add({'label': 'Category', 'value': category});
    final posted = marketTimeAgo(_item['created_at']?.toString());
    if (posted.isNotEmpty) specs.add({'label': 'Posted', 'value': posted});
    final adId = (_item['id'] ?? '').toString();
    if (adId.isNotEmpty) specs.add({'label': 'Ad ID', 'value': '#$adId'});
    final views = (_item['clicks'] ?? _item['total_clicks'] ?? '').toString();
    if (views.isNotEmpty && views != '0')
      specs.add({'label': 'Views', 'value': views});
    if (specs.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: specs.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              specs[i]['label']!,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            Text(
              specs[i]['value']!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, bool isDark) {
    return Text(
      t,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.darkForeground : AppColors.foreground,
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  final String text;
  const _SafetyTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen swipeable gallery with pinch-to-zoom.
class _FullscreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initial;

  const _FullscreenGallery({required this.photos, this.initial = 0});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initial;
    _ctrl = PageController(initialPage: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.photos.length}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              widget.photos[i],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
