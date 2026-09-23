import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/bus_booking_provider.dart';
import '../models/bus/bus_layout.dart';
import 'seat_map_screen.dart';
import 'passenger_info_screen.dart';
import '../utils/navigation.dart';

class PackageSelectionScreen extends StatelessWidget {
  const PackageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();
    final packages = busBooking.layout?.availablePackages ?? [];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            const ScreenHeader(title: 'Select Package'),
            Expanded(
              child: busBooking.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : packages.isEmpty
                  ? Center(
                      child: Text(
                        'No packages available',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${busBooking.passengers} passenger${busBooking.passengers > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkForeground
                                  : AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a package for your trip',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...packages.map(
                            (pkg) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PackageCard(
                                package: pkg,
                                isDark: isDark,
                                isSelected:
                                    busBooking.selectedPackage?.packageId ==
                                    pkg.packageId,
                                onTap: () {
                                  busBooking.selectPackage(pkg);
                                  if (pkg.allowsSeatSelection) {
                                    NavigationHelper.push(
                                      context,
                                      const SeatMapScreen(),
                                    );
                                  } else {
                                    NavigationHelper.push(
                                      context,
                                      const PassengerInfoScreen(),
                                    );
                                  }
                                },
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
}

class _PackageCard extends StatelessWidget {
  final BusPackage package;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({
    required this.package,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkGlassBorder : AppColors.glassBorder),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  package.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                Text(
                  '\u20a6${package.price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (package.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                package.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _FeatureChip(
                  icon: Icons.luggage_outlined,
                  label: '${package.luggageLimit} luggage',
                  isDark: isDark,
                ),
                _FeatureChip(
                  icon: package.allowsSeatSelection
                      ? Icons.event_seat_outlined
                      : Icons.auto_fix_high_outlined,
                  label: package.allowsSeatSelection
                      ? 'Choose seat'
                      : 'Auto-assign',
                  isDark: isDark,
                ),
                if (package.allowsReschedule)
                  _FeatureChip(
                    icon: Icons.swap_horiz_outlined,
                    label:
                        'Reschedule (\u20a6${package.rescheduleFee.toStringAsFixed(0)})',
                    isDark: isDark,
                  ),
              ],
            ),
            if (package.remainingSeats <= 5) ...[
              const SizedBox(height: 8),
              Text(
                'Only ${package.remainingSeats} seats left!',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
