import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/bus_booking_provider.dart';
import '../models/bus/bus_layout.dart';
import 'passenger_info_screen.dart';
import '../utils/navigation.dart';

class SeatMapScreen extends StatelessWidget {
  const SeatMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();
    final layout = busBooking.layout;
    final selectedPackage = busBooking.selectedPackage;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Select Seats',
              subtitle:
                  '${busBooking.selectedSeats.length}/${busBooking.passengers} selected',
            ),
            Expanded(
              child: layout == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Legend
                          _buildLegend(isDark),
                          const SizedBox(height: 16),
                          // Driver direction
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.mutedForeground,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Driver',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkMutedForeground
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Lower deck
                          if (layout.lowerLayout.isNotEmpty) ...[
                            Text(
                              'Lower Deck',
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSeatGrid(
                              layout.lowerLayout,
                              busBooking,
                              isDark,
                              selectedPackage,
                            ),
                          ],
                          // Upper deck
                          if (layout.hasUpperDeck) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Upper Deck',
                              style: GoogleFonts.sora(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkForeground
                                    : AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildSeatGrid(
                              layout.upperLayout,
                              busBooking,
                              isDark,
                              selectedPackage,
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  busBooking.selectedSeats.length ==
                                      busBooking.passengers
                                  ? () {
                                      busBooking.confirmSeats();
                                      NavigationHelper.push(
                                        context,
                                        const PassengerInfoScreen(),
                                      );
                                    }
                                  : null,
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
                                  gradient:
                                      busBooking.selectedSeats.length ==
                                          busBooking.passengers
                                      ? AppColors.gradientPrimary
                                      : null,
                                  color:
                                      busBooking.selectedSeats.length ==
                                          busBooking.passengers
                                      ? null
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Continue (${busBooking.selectedSeats.length}/${busBooking.passengers})',
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
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: isDark ? AppColors.darkGlass : AppColors.glass,
          label: 'Available',
          border: true,
        ),
        const SizedBox(width: 16),
        const _LegendItem(color: AppColors.primary, label: 'Selected'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.grey.shade400, label: 'Booked'),
        const SizedBox(width: 16),
        _LegendItem(color: Colors.orange.shade100, label: 'Reserved'),
      ],
    );
  }

  Widget _buildSeatGrid(
    List<List<Seat>> layout,
    BusBookingProvider busBooking,
    bool isDark,
    BusPackage? selectedPackage,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: layout.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...row.map((seat) {
                  if (seat.seatNumber.isEmpty) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  bool canSelect = !seat.isBooked;
                  if (selectedPackage != null &&
                      seat.reservedPackages.isNotEmpty) {
                    final reservedForHigher = seat.reservedPackages.any(
                      (p) => p.packageId > selectedPackage.packageId,
                    );
                    if (reservedForHigher) canSelect = false;
                  }

                  final isSelected = busBooking.selectedSeats.contains(
                    seat.seatNumber,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: canSelect
                          ? () => busBooking.toggleSeat(seat.seatNumber)
                          : null,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : seat.isBooked
                              ? Colors.grey.shade400
                              : seat.reservedPackages.isNotEmpty
                              ? Colors.orange.shade100
                              : (isDark ? AppColors.darkSurface : Colors.white),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            seat.seatNumber,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : seat.isBooked
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.darkForeground
                                        : AppColors.foreground),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool border;

  const _LegendItem({
    required this.color,
    required this.label,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: AppColors.border) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
