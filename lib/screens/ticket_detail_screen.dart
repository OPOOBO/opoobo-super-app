import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/module_provider.dart';
import '../providers/bus_booking_provider.dart';
import '../models/bus/booking.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();
    final booking = busBooking.selectedBooking;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            const ScreenHeader(title: 'Ticket Details'),
            Expanded(
              child: busBooking.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : booking == null
                  ? const Center(child: Text('Ticket not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // QR Code
                          if (booking.qrCode.isNotEmpty) ...[
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.network(
                                booking.qrCode,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.qr_code_outlined,
                                  size: 60,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                booking,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.bookingStatus,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(booking),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Route info
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkGlass
                                  : AppColors.glass,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkGlassBorder
                                    : AppColors.glassBorder,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          booking.busPicktime.substring(0, 5),
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? AppColors.darkForeground
                                                : AppColors.foreground,
                                          ),
                                        ),
                                        Text(
                                          booking.boardingCity,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.darkMutedForeground
                                                : AppColors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.arrow_forward_outlined,
                                            size: 24,
                                            color: AppColors.primary,
                                          ),
                                          Text(
                                            booking.differencePickDrop,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors
                                                        .darkMutedForeground
                                                  : AppColors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          booking.busDroptime.substring(0, 5),
                                          style: GoogleFonts.inter(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? AppColors.darkForeground
                                                : AppColors.foreground,
                                          ),
                                        ),
                                        Text(
                                          booking.dropCity,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.darkMutedForeground
                                                : AppColors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                _buildInfoRow('Date', booking.bookDate, isDark),
                                _buildInfoRow('Bus', booking.busName, isDark),
                                _buildInfoRow(
                                  'Seats',
                                  '${booking.totalSeat ?? booking.passengers?.length ?? 0}',
                                  isDark,
                                ),
                                _buildInfoRow(
                                  'Amount',
                                  '\u20a6${booking.total ?? booking.subtotal}',
                                  isDark,
                                ),
                                if (booking.pMethodName != null)
                                  _buildInfoRow(
                                    'Payment',
                                    booking.pMethodName!,
                                    isDark,
                                  ),
                                if (booking.transactionId != null)
                                  _buildInfoRow(
                                    'Trans. ID',
                                    booking.transactionId!,
                                    isDark,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Boarding/dropping details
                          if (booking.subPickPlace != null) ...[
                            _buildLocationCard(
                              'Boarding Point',
                              booking.subPickPlace!,
                              booking.subPickAddress ?? '',
                              booking.subPickTime?.substring(0, 5) ?? '',
                              isDark,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (booking.subDropPlace != null)
                            _buildLocationCard(
                              'Dropping Point',
                              booking.subDropPlace!,
                              booking.subDropAddress ?? '',
                              booking.subDropTime?.substring(0, 5) ?? '',
                              isDark,
                            ),
                          // Passengers
                          if (booking.passengers != null &&
                              booking.passengers!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Passengers',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkForeground
                                      : AppColors.foreground,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...booking.passengers!.map(
                              (p) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkGlass
                                      : AppColors.glass,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkGlassBorder
                                        : AppColors.glassBorder,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          p.seatNo.isNotEmpty
                                              ? p.seatNo
                                              : p.name.isNotEmpty
                                              ? p.name[0]
                                              : '?',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name.isNotEmpty
                                                ? p.name
                                                : 'Passenger',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? AppColors.darkForeground
                                                  : AppColors.foreground,
                                            ),
                                          ),
                                          Text(
                                            '${p.age} yrs \u00b7 ${p.gender}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? AppColors
                                                        .darkMutedForeground
                                                  : AppColors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // Cancel button
                          if (booking.cancleShow == 1 &&
                              !booking.isCancelled) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _showCancelDialog(context, booking),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.destructive,
                                  ),
                                ),
                                child: Text(
                                  'Cancel Ticket',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.destructive,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(Booking booking) {
    if (booking.isConfirmed) return AppColors.success;
    if (booking.isCancelled) return AppColors.destructive;
    return AppColors.primary;
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    String name,
    String address,
    String time,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                Text(
                  address,
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
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Cancel Ticket',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to cancel this ticket?',
              style: GoogleFonts.inter(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason for cancellation',
                hintStyle: GoogleFonts.inter(fontSize: 13),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkBackground
                    : AppColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Keep Ticket',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final busUid =
                  context.read<ModuleProvider>().getModuleUid('bus') ?? '';
              context.read<BusBookingProvider>().cancelTicket(
                busUid,
                booking.ticketId,
                double.tryParse(booking.total ?? booking.subtotal) ?? 0,
                reasonController.text,
              );
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
