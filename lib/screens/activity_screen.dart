import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/bus_booking_provider.dart';
import '../providers/module_provider.dart';
import '../models/bus/booking.dart';
import '../services/market_service.dart';
import '../screens/ticket_detail_screen.dart';
import '../screens/market_chat_thread_screen.dart';
import '../utils/navigation.dart';
import '../widgets/screen_header.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _tab = 'Activity';
  String _filter = 'All';
  String _search = '';
  final MarketService _market = MarketService();
  List<Map<String, dynamic>> _myOffers = [];
  List<dynamic> _notifications = [];
  bool _loadingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
      _loadMyOffers();
    });
  }

  void _loadBookings() {
    final moduleProvider = context.read<ModuleProvider>();
    final busUid = moduleProvider.getModuleUid('bus');
    if (busUid != null && busUid.isNotEmpty) {
      context.read<BusBookingProvider>().loadBookingHistory(busUid);
    }
  }

  Future<void> _loadMyOffers() async {
    try {
      final result = await _market.getMyOffers();
      if (!mounted) return;
      setState(() {
        _myOffers = _flattenOffers(result);
      });
    } catch (_) {}
  }

  Future<void> _loadNotifications() async {
    setState(() => _loadingNotifications = true);
    final result = await _market.getNotifications();
    if (!mounted) return;
    setState(() {
      final data = result?['data'];
      final list = data is List
          ? data
          : data is Map
              ? (data['notifications'] as List<dynamic>? ?? [])
              : [];
      _notifications = list;
      _loadingNotifications = false;
    });
  }

  List<Map<String, dynamic>> _flattenOffers(Map<String, dynamic>? res) {
    if (!marketSuccess(res)) return [];
    dynamic d = res!['data'];
    List<dynamic> items = [];
    if (d is Map && d['data'] is List) {
      items = d['data'];
    } else if (d is List) {
      items = d;
    }
    final out = <Map<String, dynamic>>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final offers = item['item_offers'];
      if (offers is List) {
        for (final o in offers) {
          if (o is! Map) continue;
          final offer = Map<String, dynamic>.from(o);
          offer['item_title'] = item['translated_name'] ?? item['name'] ?? '';
          offer['item_image'] = item['image'] ?? '';
          offer['item_price'] =
              item['formatted_price'] ?? item['price']?.toString() ?? '';
          out.add(offer);
        }
      }
    }
    return out;
  }

  Future<void> _onRefresh() async {
    _loadBookings();
    await _loadMyOffers();
    if (_tab == 'Alerts') await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();
    final bookings = busBooking.bookings;

    List<Booking> filtered = bookings;
    if (_filter == 'Pending') {
      filtered = bookings.where((b) => b.isPending).toList();
    } else if (_filter == 'Completed') {
      filtered = bookings.where((b) => b.isConfirmed).toList();
    } else if (_filter == 'Cancelled') {
      filtered = bookings.where((b) => b.isCancelled).toList();
    }

    if (_search.isNotEmpty) {
      filtered = filtered
          .where(
            (b) =>
                b.boardingCity.toLowerCase().contains(_search.toLowerCase()) ||
                b.dropCity.toLowerCase().contains(_search.toLowerCase()),
          )
          .toList();
    }

    final totalActivities = filtered.length + _myOffers.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Activity',
            subtitle: _tab == 'Activity' ? 'All your bookings & offers' : 'Stay updated',
            showBack: true,
          ),
          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _TabButton(
                  label: 'Activity',
                  isActive: _tab == 'Activity',
                  isDark: isDark,
                  onTap: () => setState(() {
                    _tab = 'Activity';
                    _search = '';
                  }),
                ),
                const SizedBox(width: 8),
                _TabButton(
                  label: 'Alerts',
                  isActive: _tab == 'Alerts',
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      _tab = 'Alerts';
                      _search = '';
                    });
                    if (_notifications.isEmpty) _loadNotifications();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_tab == 'Activity') ...[
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search activity...',
                  prefixIcon: const Icon(Icons.search_outlined, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Pending', 'Completed', 'Cancelled']
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? Colors.white
                                  : AppColors.mutedForeground,
                            ),
                          ),
                          selected: _filter == f,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          side: BorderSide.none,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: ['All', 'Trips', 'Payments', 'Market']
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? Colors.white
                                  : AppColors.mutedForeground,
                            ),
                          ),
                          selected: _filter == f,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          side: BorderSide.none,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _tab == 'Activity'
                ? _buildActivityTab(isDark, totalActivities, filtered)
                : _buildAlertsTab(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(bool isDark, int totalActivities, List<Booking> filtered) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: totalActivities == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No activity yet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (filtered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Bus Trips',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...filtered.map(
                    (b) => _BusBookingTile(
                      booking: b,
                      onTap: () {
                        final busUid =
                            context.read<ModuleProvider>().getModuleUid('bus') ??
                                '';
                        context
                            .read<BusBookingProvider>()
                            .loadBookingDetails(busUid, b.ticketId)
                            .then((_) {
                              if (mounted) {
                                NavigationHelper.push(
                                  context,
                                  const TicketDetailScreen(),
                                );
                              }
                            });
                      },
                    ),
                  ),
                ],
                if (_myOffers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'My Offers',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ..._myOffers.map(
                    (offer) => _OfferTile(
                      offer: offer,
                      onTap: () {
                        final oid = (offer['id'] as num?)?.toInt();
                        if (oid == null) return;
                        final bid = offer['buyer_id'];
                        NavigationHelper.push(
                          context,
                          MarketChatThreadScreen(
                            offer: {'id': oid, 'buyer_id': bid},
                            myUserId:
                                bid == null ? null : (bid as num).toInt(),
                            itemTitle: (offer['item_title'] ?? '').toString(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildAlertsTab(bool isDark) {
    if (_loadingNotifications) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notifications.length,
              itemBuilder: (ctx, i) =>
                  _NotificationTile(data: _notifications[i]),
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.gradientPrimary : null,
          color: isActive ? null : (isDark ? AppColors.darkSurface : AppColors.secondary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : (isDark ? AppColors.darkForeground : AppColors.foreground),
          ),
        ),
      ),
    );
  }
}

class _BusBookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  const _BusBookingTile({required this.booking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking.boardingCity} \u2192 ${booking.dropCity}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    booking.bookDate,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: booking.isConfirmed
                    ? AppColors.success.withValues(alpha: 0.1)
                    : booking.isCancelled
                    ? AppColors.destructive.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.bookingStatus,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: booking.isConfirmed
                      ? AppColors.success
                      : booking.isCancelled
                      ? AppColors.destructive
                      : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onTap;
  const _OfferTile({required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = (offer['item_title'] ?? '').toString();
    final amount =
        (offer['item_offer_formatted_amount'] ?? offer['amount'] ?? '')
            .toString();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    amount.isNotEmpty ? 'Offer: \u20a6$amount' : 'Chat started',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_outlined,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic data;
  const _NotificationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = data['title'] ?? data['name'] ?? 'Notification';
    final body = data['description'] ?? data['body'] ?? data['message'] ?? '';
    final time = data['created_at'] ?? data['time'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
                if (time.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
