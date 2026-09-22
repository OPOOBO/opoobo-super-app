import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../widgets/opoobo_logo.dart';
import '../widgets/screen_header.dart';
import 'module_registration_screen.dart';
import 'home_screen.dart';
import '../utils/navigation.dart';

class ModuleOnboardingScreen extends StatefulWidget {
  const ModuleOnboardingScreen({super.key});

  @override
  State<ModuleOnboardingScreen> createState() => _ModuleOnboardingScreenState();
}

class _ModuleOnboardingScreenState extends State<ModuleOnboardingScreen> {
  final _emailController = TextEditingController();
  bool _checking = false;
  List<EmailCheckResult> _checkResults = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _emailController.text = auth.displayEmail;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ModuleProvider>().loadModules();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkEmail() async {
    if (_emailController.text.isEmpty) return;

    setState(() {
      _checking = true;
    });

    final results = await context.read<ModuleProvider>().checkEmail(
      email: _emailController.text,
    );

    setState(() {
      _checking = false;
      _checkResults = results;
    });
  }

  void _linkModule(ModuleData module, EmailCheckResult? checkResult) {
    NavigationHelper.push(
      context,
      ModuleRegistrationScreen(
        module: module,
        existingEmail: _emailController.text,
      ),
    );
  }

  void _skip() {
    NavigationHelper.pushReplacement(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleProvider = context.watch<ModuleProvider>();
    final modules = moduleProvider.modules;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Connect Your Services',
              subtitle: 'Link your existing OPOOBO accounts or create new ones',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    _buildWelcomeCard(isDark),
                    const SizedBox(height: 24),

                    // Email check section
                    _buildEmailCheckSection(isDark),
                    const SizedBox(height: 24),

                    // Check results
                    if (_checkResults.isNotEmpty) ...[
                      _buildCheckResults(isDark),
                      const SizedBox(height: 24),
                    ],

                    // All available modules
                    if (modules.where((m) => m.isActive).isNotEmpty) ...[
                      Text(
                        'Available Services',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...modules
                          .where((m) => m.isActive)
                          .map((module) => _buildModuleCard(isDark, module)),
                      const SizedBox(height: 16),
                    ],

                    // Skip button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _skip,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkMutedForeground
                                : AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    final auth = context.read<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const OpooboLogo(size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${auth.displayName}!',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s connect your OPOOBO services for a seamless experience.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCheckSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check existing accounts',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your email to check if you have accounts on other OPOOBO services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_rounded, size: 18),
                    filled: true,
                    fillColor:
                        (isDark ? AppColors.darkSurface : AppColors.surface)
                            .withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _checking ? null : _checkEmail,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _checking ? null : AppColors.gradientPrimary,
                    color: _checking ? Colors.grey : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckResults(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkForeground : AppColors.foreground,
          ),
        ),
        const SizedBox(height: 12),
        ..._checkResults.map((result) {
          final module = context.read<ModuleProvider>().modules.firstWhere(
            (m) => m.name == result.module,
            orElse: () => ModuleData(id: 0, name: '', displayName: ''),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: result.exists
                  ? Colors.green.withValues(alpha: 0.1)
                  : (isDark ? AppColors.darkGlass : AppColors.glass),
              border: Border.all(
                color: result.exists
                    ? Colors.green.withValues(alpha: 0.3)
                    : (isDark
                          ? AppColors.darkGlassBorder
                          : AppColors.glassBorder),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: result.exists
                        ? Colors.green.withValues(alpha: 0.2)
                        : (isDark
                              ? AppColors.darkSurface
                              : AppColors.secondary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getModuleIcon(result.module),
                    color: result.exists ? Colors.green : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.displayName,
                        style: GoogleFonts.sora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.exists
                            ? 'Account found! ${result.name != null ? '(${result.name})' : ''}'
                            : 'No account found',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: result.exists
                              ? Colors.green
                              : (isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.exists)
                  GestureDetector(
                    onTap: () => _linkModule(module, result),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Link',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModuleCard(bool isDark, ModuleData module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: module.isLinked
                  ? Colors.green.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkSurface : AppColors.secondary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getModuleIcon(module.name),
              color: module.isLinked ? Colors.green : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.displayName,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.description ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (module.isLinked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Linked',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _linkModule(module, null),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Connect',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getModuleIcon(String moduleName) {
    switch (moduleName) {
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'market':
        return Icons.shopping_cart_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'ride':
        return Icons.directions_car_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
