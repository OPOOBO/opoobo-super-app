import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offer_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/offer_cards.dart';
import '../widgets/screen_header.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferProvider>().loadDeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offers = context.watch<OfferProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(
            title: 'Daily Deals',
            subtitle: 'Placeholder offers — redemption comes later',
          ),
          Expanded(
            child: offers.loadingDeals && offers.deals.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      if (offers.deals.isEmpty)
                        Text(
                          offers.dealsError ?? 'No deals right now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : AppColors.mutedForeground,
                          ),
                        )
                      else
                        for (final deal in offers.deals) ...[
                          DealRow(deal: deal, isDark: isDark),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
