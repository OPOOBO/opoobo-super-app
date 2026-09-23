import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../core/bus_api_client.dart';
import '../core/user_api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../providers/bus_booking_provider.dart';
import '../providers/flutterwave_auth_provider.dart';
import '../models/user_models.dart';
import 'booking_success_screen.dart';
import '../utils/navigation.dart';

class BusPaymentScreen extends StatefulWidget {
  const BusPaymentScreen({super.key});

  @override
  State<BusPaymentScreen> createState() => _BusPaymentScreenState();
}

class _BusPaymentScreenState extends State<BusPaymentScreen> {
  final _couponController = TextEditingController();
  bool _paying = false;
  SavedAuthorizationData? _selectedAuth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlutterwaveAuthProvider>().load();
      context.read<BusBookingProvider>().generateTransactionId();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    if (_couponController.text.trim().isEmpty) return;
    final busUid = context.read<ModuleProvider>().getModuleUid('bus') ?? '';
    context.read<BusBookingProvider>().applyCoupon(
      busUid,
      _couponController.text.trim(),
    );
  }

  /// Pay with a saved card — charges via backend, no Flutterwave UI.
  Future<void> _payWithSavedCard() async {
    final busBooking = context.read<BusBookingProvider>();
    final auth = context.read<AuthProvider>();
    final fwAuth = context.read<FlutterwaveAuthProvider>();
    final busUid = context.read<ModuleProvider>().getModuleUid('bus') ?? '';
    final email = auth.displayEmail.isNotEmpty
        ? auth.displayEmail
        : 'ticket@opoobo.com';
    final currency =
        busBooking.currency.length == 3 ? busBooking.currency : 'NGN';

    setState(() => _paying = true);

    try {
      final result = await fwAuth.chargeSaved(
        authorizationCode: _selectedAuth!.authorizationCode,
        amount: busBooking.total,
        currency: currency,
        email: email,
        txRef: busBooking.transactionId,
      );

      if (result['success'] == true) {
        final booked = await busBooking.bookTicket(busUid);
        if (booked && mounted) {
          NavigationHelper.pushReplacement(
            context,
            const BookingSuccessScreen(),
          );
        } else if (mounted && busBooking.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(busBooking.error!)));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Payment failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
    setState(() => _paying = false);
  }

  /// Pay with new card — opens Flutterwave UI, verifies + saves authorization on success.
  Future<void> _payWithNewCard() async {
    final busBooking = context.read<BusBookingProvider>();
    final auth = context.read<AuthProvider>();
    final fwAuth = context.read<FlutterwaveAuthProvider>();
    final busUid = context.read<ModuleProvider>().getModuleUid('bus') ?? '';
    final email = auth.displayEmail.isNotEmpty
        ? auth.displayEmail
        : 'ticket@opoobo.com';
    final name = auth.displayName;
    final currency =
        busBooking.currency.length == 3 ? busBooking.currency : 'NGN';

    setState(() => _paying = true);

    try {
      final flutterwave = Flutterwave(
        publicKey: BusApiClient.flutterwavePublicKey,
        currency: currency,
        txRef: busBooking.transactionId,
        amount: busBooking.total.toString(),
        customer: Customer(email: email, name: name),
        paymentOptions: 'card',
        redirectUrl: 'https://opoobo.com/payment/callback',
        customization: Customization(
          title: 'OPOOBO Bus Ticket',
          description:
              '${busBooking.fromCity?.title ?? ""} to ${busBooking.toCity?.title ?? ""}',
        ),
        isTestMode: false,
      );

      final response = await flutterwave.charge(context);

      if (response.success == true) {
        // Verify transaction to get authorization details
        try {
          final verifyApi = UserApiClient();
          final verifyResult = await verifyApi.verifyTransaction(
            busBooking.transactionId,
          );
          if (verifyResult['success'] == true) {
            final txData = verifyResult['data'];
            final authData = txData?['authorization'];
            if (authData != null && authData is Map) {
              await fwAuth.save(
                authorizationCode: authData['authorization_code'] ?? '',
                cardType: authData['card_type'] ?? '',
                lastFour: authData['last4'] ?? '',
                expMonth: authData['exp_month'],
                expYear: authData['exp_year'],
                bankName: authData['bank_name'],
              );
            }
          }
        } catch (_) {
          // Authorization save failed silently — payment still succeeded
        }

        final booked = await busBooking.bookTicket(busUid);
        if (booked && mounted) {
          NavigationHelper.pushReplacement(
            context,
            const BookingSuccessScreen(),
          );
        } else if (mounted && busBooking.error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(busBooking.error!)));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment was not completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    }
    setState(() => _paying = false);
  }

  void _pay() {
    if (_selectedAuth != null) {
      _payWithSavedCard();
    } else {
      _payWithNewCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busBooking = context.watch<BusBookingProvider>();
    final bus = busBooking.selectedBus;
    final fwProvider = context.watch<FlutterwaveAuthProvider>();
    final savedAuths = fwProvider.authorizations;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            const ScreenHeader(title: 'Payment'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fare summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkGlass : AppColors.glass,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkGlassBorder
                              : AppColors.glassBorder,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.directions_bus_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${busBooking.fromCity?.title ?? ""} \u2192 ${busBooking.toCity?.title ?? ""}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkForeground
                                        : AppColors.foreground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildFareRow(
                            'Package',
                            busBooking.selectedPackage?.name ?? '-',
                            isDark,
                          ),
                          _buildFareRow(
                            'Passengers',
                            '${busBooking.passengers}',
                            isDark,
                          ),
                          if (busBooking.selectedSeats.isNotEmpty)
                            _buildFareRow(
                              'Seats',
                              busBooking.selectedSeats.join(', '),
                              isDark,
                            ),
                          _buildFareRow(
                            'Route',
                            '${bus?.boardingCity ?? ""} \u2192 ${bus?.dropCity ?? ""}',
                            isDark,
                          ),
                          _buildFareRow(
                            'Date',
                            '${busBooking.departureDate.day}/${busBooking.departureDate.month}/${busBooking.departureDate.year}',
                            isDark,
                          ),
                          const Divider(height: 20),
                          _buildFareRow(
                            'Ticket price',
                            '\u20a6${busBooking.ticketPrice.toStringAsFixed(0)} x ${busBooking.passengers}',
                            isDark,
                          ),
                          _buildFareRow(
                            'Subtotal',
                            '\u20a6${busBooking.subtotal.toStringAsFixed(0)}',
                            isDark,
                          ),
                          if (busBooking.couponDiscount > 0)
                            _buildFareRow(
                              'Discount',
                              '-\u20a6${busBooking.couponDiscount.toStringAsFixed(0)}',
                              isDark,
                              valueColor: AppColors.success,
                            ),
                          const Divider(height: 20),
                          _buildFareRow(
                            'Total',
                            '\u20a6${busBooking.total.toStringAsFixed(0)}',
                            isDark,
                            isBold: true,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Saved cards
                    if (savedAuths.isNotEmpty) ...[
                      Text(
                        'Saved cards',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...savedAuths.map((a) => GestureDetector(
                        onTap: () => setState(() => _selectedAuth = a),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedAuth?.id == a.id
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border),
                              width: _selectedAuth?.id == a.id ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      a.subtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedAuth?.id == a.id)
                                const Icon(
                                  Icons.check_circle_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      )),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAuth != null
                            ? 'Pay instantly with ${_selectedAuth!.displayName}'
                            : 'Select a card or pay with a new one',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Coupon
                    Text(
                      'Have a coupon?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.secondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _applyCoupon,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (busBooking.appliedCoupon != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Coupon "${busBooking.appliedCoupon!.couponCode}" applied! \u20a6${busBooking.couponDiscount.toStringAsFixed(0)} off',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Pay button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _paying ? null : _pay,
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
                                _paying ? null : AppColors.gradientPrimary,
                            color: _paying ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: _paying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  _selectedAuth != null
                                      ? 'Pay \u20a6${busBooking.total.toStringAsFixed(0)} with ${_selectedAuth!.displayName}'
                                      : 'Pay \u20a6${busBooking.total.toStringAsFixed(0)}',
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

  Widget _buildFareRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ??
                  (isDark ? AppColors.darkForeground : AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
