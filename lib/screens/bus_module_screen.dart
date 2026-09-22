import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/module_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bus_booking_provider.dart';
import 'bus_results_screen.dart';
import 'booking_history_screen.dart';
import '../utils/navigation.dart';

class BusModuleScreen extends StatefulWidget {
  const BusModuleScreen({super.key});

  @override
  State<BusModuleScreen> createState() => _BusModuleScreenState();
}

class _BusModuleScreenState extends State<BusModuleScreen> {
  bool _linking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusBookingProvider>().loadCities();
    });
  }

  void _showCityPicker({required bool isFrom}) {
    final busBooking = context.read<BusBookingProvider>();
    final cities = busBooking.cities;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final filterController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = cities
                .where(
                  (c) => c.title.toLowerCase().contains(
                    filterController.text.toLowerCase(),
                  ),
                )
                .toList();
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: filterController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search cities...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurface
                            : AppColors.secondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              busBooking.loading
                                  ? 'Loading cities...'
                                  : 'No cities found',
                              style: GoogleFonts.plusJakartaSans(
                                color: isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final city = filtered[index];
                              return ListTile(
                                leading: Icon(
                                  isFrom
                                      ? Icons.circle_outlined
                                      : Icons.location_on_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  city.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkForeground
                                        : AppColors.foreground,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onTap: () {
                                  if (isFrom) {
                                    busBooking.setFromCity(city);
                                  } else {
                                    busBooking.setToCity(city);
                                  }
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _searchBuses() async {
    final busBooking = context.read<BusBookingProvider>();

    if (busBooking.fromCity == null || busBooking.toCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both cities')),
      );
      return;
    }

    // Bus UID comes from SSO auto-link — never ask the user for extra
    // details. If it's not loaded yet, link silently in the background.
    String? busUid = context.read<ModuleProvider>().getModuleUid('bus');
    if (busUid == null || busUid.isEmpty) {
      if (!mounted) return;
      setState(() => _linking = true);
      try {
        await context.read<AuthProvider>().ensureModulesLinked();
        await context.read<ModuleProvider>().loadModules();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _linking = false);
      busUid = context.read<ModuleProvider>().getModuleUid('bus');
      if (busUid == null || busUid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not set up your bus account. Check your connection and retry.',
            ),
            action: SnackBarAction(label: 'Retry', onPressed: _searchBuses),
          ),
        );
        return;
      }
    }

    final uid = busUid;
    busBooking.searchBuses(uid).then((_) {
      if (mounted && busBooking.error == null) {
        NavigationHelper.push(context, const BusResultsScreen());
      } else if (mounted && busBooking.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(busBooking.error!)));
      }
    });
  }

  String _formatDate(DateTime date) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[date.weekday % 7]}, ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            ScreenHeader(
              title: 'OPOOBO Bus',
              subtitle: 'Book interstate & intercity trips',
              action: GestureDetector(
                onTap: () => NavigationHelper.push(
                  context,
                  const BookingHistoryScreen(),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPromoBanner(isDark),
                    const SizedBox(height: 16),
                    _buildSearchForm(isDark, busBooking),
                    const SizedBox(height: 20),
                    _buildPopularDestinations(isDark, busBooking),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 34,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekend deal',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '15% off interstate trips',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use code OPB15 \u00b7 ends Sunday',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm(bool isDark, BusBookingProvider busBooking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          // From city
          GestureDetector(
            onTap: () => _showCityPicker(isFrom: true),
            child: _LocationField(
              icon: Icons.circle_outlined,
              label: 'From',
              value: busBooking.fromCity?.title ?? 'Select city',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 8),
          // Swap button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: busBooking.swapCities,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // To city
          GestureDetector(
            onTap: () => _showCityPicker(isFrom: false),
            child: _LocationField(
              icon: Icons.location_on_rounded,
              label: 'To',
              value: busBooking.toCity?.title ?? 'Select city',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),
          // Date and passengers
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: busBooking.departureDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) busBooking.setDepartureDate(picked);
                  },
                  child: _InfoField(
                    icon: Icons.calendar_today_rounded,
                    label: 'Departure',
                    value: _formatDate(busBooking.departureDate),
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkSurface : AppColors.surface)
                        .withValues(alpha: 0.7),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSENGERS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => busBooking.setPassengers(
                              busBooking.passengers - 1,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove_rounded, size: 18),
                            ),
                          ),
                          Text(
                            '${busBooking.passengers}',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkForeground
                                  : AppColors.foreground,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => busBooking.setPassengers(
                              busBooking.passengers + 1,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (busBooking.loading || _linking) ? null : _searchBuses,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
                elevation: 0,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: (busBooking.loading || _linking)
                      ? null
                      : AppColors.gradientPrimary,
                  color: (busBooking.loading || _linking) ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: (busBooking.loading || _linking)
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            blurRadius: 34,
                            offset: const Offset(0, 10),
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: (busBooking.loading || _linking)
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Search Buses',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularDestinations(bool isDark, BusBookingProvider busBooking) {
    final cities = busBooking.cities.take(6).toList();
    if (cities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular destinations',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkForeground : AppColors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cities.map((city) {
            return GestureDetector(
              onTap: () => busBooking.setToCity(city),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGlass : AppColors.glass,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.glassBorder,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  city.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _LocationField({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.7,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value.contains('Select')
                        ? (isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground)
                        : (isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoField({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.7,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
