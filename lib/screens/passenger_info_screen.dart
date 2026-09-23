import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../widgets/floating_field.dart';
import '../providers/auth_provider.dart';
import '../providers/bus_booking_provider.dart';
import 'bus_payment_screen.dart';
import '../utils/navigation.dart';

class PassengerInfoScreen extends StatefulWidget {
  const PassengerInfoScreen({super.key});

  @override
  State<PassengerInfoScreen> createState() => _PassengerInfoScreenState();
}

class _PassengerInfoScreenState extends State<PassengerInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late List<TextEditingController> _passengerNameControllers;
  late List<int> _passengerAges;
  late List<String> _passengerGenders;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.displayName);
    _emailController = TextEditingController(text: auth.displayEmail);
    _phoneController = TextEditingController(text: auth.displayPhone);
    final busBooking = context.read<BusBookingProvider>();
    _passengerNameControllers = List.generate(
      busBooking.passengers,
      (i) => TextEditingController(text: busBooking.passengerInputs[i].name),
    );
    _passengerAges = List.generate(
      busBooking.passengers,
      (i) => busBooking.passengerInputs[i].age,
    );
    _passengerGenders = List.generate(
      busBooking.passengers,
      (i) => busBooking.passengerInputs[i].gender,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    for (final c in _passengerNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in contact information')),
      );
      return;
    }
    for (int i = 0; i < _passengerNameControllers.length; i++) {
      if (_passengerNameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter name for passenger ${i + 1}')),
        );
        return;
      }
    }

    final busBooking = context.read<BusBookingProvider>();
    busBooking.updateContactInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    for (int i = 0; i < _passengerNameControllers.length; i++) {
      busBooking.updatePassenger(
        i,
        PassengerInput(
          name: _passengerNameControllers[i].text.trim(),
          age: _passengerAges[i],
          gender: _passengerGenders[i],
          seatNo: busBooking.passengerInputs[i].seatNo,
        ),
      );
    }
    busBooking.proceedToPayment();
    NavigationHelper.push(context, const BusPaymentScreen());
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
            const ScreenHeader(title: 'Passenger Info'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact info
                    Text(
                      'Contact Information',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FloatingField(
                      label: 'Full name',
                      icon: Icons.person_outlined,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 12),
                    FloatingField(
                      label: 'Email',
                      icon: Icons.mail_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 12),
                    FloatingField(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      controller: _phoneController,
                    ),
                    const SizedBox(height: 24),
                    // Passengers
                    Text(
                      'Passengers (${busBooking.passengers})',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (busBooking.selectedPackage?.allowsSeatSelection ==
                        false)
                      Text(
                        'Seats will be auto-assigned',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      busBooking.passengers,
                      (index) => _buildPassengerCard(index, isDark),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _continue,
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
                          child: Text(
                            'Continue to Payment',
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

  Widget _buildPassengerCard(int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger ${index + 1}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passengerNameControllers[index],
            decoration: InputDecoration(
              hintText: 'Full name',
              hintStyle: GoogleFonts.inter(fontSize: 13),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.secondary,
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<int>(
                    value: _passengerAges[index],
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    items: List.generate(
                      80,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() => _passengerAges[index] = v ?? 25),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _passengerGenders[index],
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDark
                        ? AppColors.darkSurface
                        : AppColors.surface,
                    items: ['MALE', 'FEMALE']
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g[0] + g.substring(1).toLowerCase(),
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _passengerGenders[index] = v ?? 'MALE'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
