import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/module_provider.dart';
import '../providers/bus_booking_provider.dart';
import 'package_selection_screen.dart';
import '../utils/navigation.dart';

class BoardingPointsScreen extends StatefulWidget {
  const BoardingPointsScreen({super.key});

  @override
  State<BoardingPointsScreen> createState() => _BoardingPointsScreenState();
}

class _BoardingPointsScreenState extends State<BoardingPointsScreen> {
  int? _selectedPickupIndex;
  int? _selectedDropIndex;

  void _continue() {
    if (_selectedPickupIndex == null || _selectedDropIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both boarding and dropping points'),
        ),
      );
      return;
    }
    final busBooking = context.read<BusBookingProvider>();
    final pickup = busBooking.pickupPoints[_selectedPickupIndex!];
    final drop = busBooking.dropPoints[_selectedDropIndex!];
    final uid = context.read<ModuleProvider>().getModuleUid('bus') ?? '';

    busBooking.selectBoardingPoints(pickup: pickup, drop: drop, uid: uid).then((
      _,
    ) {
      if (mounted && busBooking.error == null) {
        NavigationHelper.push(context, const PackageSelectionScreen());
      } else if (mounted && busBooking.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(busBooking.error!)));
      }
    });
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
            const ScreenHeader(title: 'Boarding & Drop Points'),
            Expanded(
              child: busBooking.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Boarding Point', isDark),
                          const SizedBox(height: 10),
                          ...busBooking.pickupPoints.asMap().entries.map(
                            (entry) => _buildPointCard(
                              isDark: isDark,
                              title: entry.value.pickPlace,
                              time: entry.value.pickTime.substring(0, 5),
                              address: entry.value.pickAddress,
                              phone: entry.value.pickMobile,
                              isSelected: _selectedPickupIndex == entry.key,
                              onTap: () => setState(
                                () => _selectedPickupIndex = entry.key,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Dropping Point', isDark),
                          const SizedBox(height: 10),
                          ...busBooking.dropPoints.asMap().entries.map(
                            (entry) => _buildPointCard(
                              isDark: isDark,
                              title: entry.value.dropPlace,
                              time: entry.value.dropTime.substring(0, 5),
                              address: entry.value.dropAddress,
                              phone: entry.value.dropMobile,
                              isSelected: _selectedDropIndex == entry.key,
                              onTap: () => setState(
                                () => _selectedDropIndex = entry.key,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: busBooking.loading ? null : _continue,
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
                                  gradient: AppColors.gradientPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: busBooking.loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Continue to Package Selection',
                                        style: GoogleFonts.inter(
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
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.darkForeground : AppColors.foreground,
      ),
    );
  }

  Widget _buildPointCard({
    required bool isDark,
    required String title,
    required String time,
    required String address,
    required String phone,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkGlassBorder : AppColors.glassBorder),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : (isDark ? AppColors.darkSurface : AppColors.secondary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                  ),
                  Text(
                    '$time \u00b7 $address',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_outlined,
                size: 22,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
