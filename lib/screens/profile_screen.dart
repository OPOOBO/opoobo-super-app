import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/navigation.dart';
import 'connected_apps_screen.dart';
import 'payment_methods_screen.dart';
import 'addresses_screen.dart';
import 'saved_locations_screen.dart';
import 'security_settings_screen.dart';
import 'privacy_screen.dart';
import 'language_screen.dart';
import 'help_center_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          0,
          MediaQuery.of(context).padding.top,
          0,
          120,
        ),
        child: Column(
          children: [
            const ScreenHeader(title: 'Profile', showBack: false),
            const SizedBox(height: 24),
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  auth.initials,
                  style: GoogleFonts.sora(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    auth.displayName,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.badge_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              auth.displayEmail,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              auth.displayPhone.isNotEmpty ? auth.displayPhone : 'No phone set',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            // Member info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoChip(
                    label:
                        'OPB-${auth.opooboId.substring(0, _min(auth.opooboId.length, 8))}',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${auth.memberTierLabel} Member',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Dark mode toggle
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              label: 'Dark mode',
              trailing: Switch(
                value: isDark,
                onChanged: (v) {
                  context.read<ThemeProvider>().setDark(v);
                },
                activeThumbColor: AppColors.primary,
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            // Account section
            _SectionLabel(label: 'ACCOUNT', isDark: isDark),
            _SettingsTile(
              icon: Icons.grid_view_rounded,
              label: 'Connected apps',
              trailingText:
                  '${context.read<ModuleProvider>().modules.length}',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const ConnectedAppsScreen()),
            ),
            _SettingsTile(
              icon: Icons.credit_card_rounded,
              label: 'Payment methods',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const PaymentMethodsScreen()),
            ),
            _SettingsTile(
              icon: Icons.home_rounded,
              label: 'Addresses',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const AddressesScreen()),
            ),
            _SettingsTile(
              icon: Icons.location_on_rounded,
              label: 'Saved locations',
              isDark: isDark,
              onTap: () => NavigationHelper.push(
                  context, const SavedLocationsScreen()),
            ),
            const SizedBox(height: 8),
            // Security section
            _SectionLabel(label: 'SECURITY & PRIVACY', isDark: isDark),
            _SettingsTile(
              icon: Icons.shield_rounded,
              label: 'Security settings',
              isDark: isDark,
              onTap: () => NavigationHelper.push(
                  context, const SecuritySettingsScreen()),
            ),
            _SettingsTile(
              icon: Icons.lock_rounded,
              label: 'Privacy',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const PrivacyScreen()),
            ),
            _SettingsTile(
              icon: Icons.language_rounded,
              label: 'Language',
              trailingText: 'English NG',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const LanguageScreen()),
            ),
            const SizedBox(height: 8),
            // Support section
            _SectionLabel(label: 'SUPPORT', isDark: isDark),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Help Center',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const HelpCenterScreen()),
            ),
            _SettingsTile(
              icon: Icons.info_rounded,
              label: 'About OPOOBO',
              trailingText: 'v1.0.0',
              isDark: isDark,
              onTap: () =>
                  NavigationHelper.push(context, const AboutScreen()),
            ),
            const SizedBox(height: 24),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _loggingOut ? null : _handleLogout,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_loggingOut)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.destructive,
                          ),
                        )
                      else
                        const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: AppColors.destructive,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _loggingOut ? 'Logging out...' : 'Log out',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'OPOOBO \u00b7 v1.0.0 (build 240)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    await context.read<AuthProvider>().logout();
    if (mounted) {
      NavigationHelper.popToRoot(context);
    }
  }
}

int _min(int a, int b) => a < b ? a : b;

class _InfoChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _InfoChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkGlass : AppColors.glass,
        border: Border.all(
          color: isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkForeground : AppColors.foreground,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: isDark
              ? AppColors.darkMutedForeground
              : AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? trailingText;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingText,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkGlass : AppColors.glass,
            border: Border.all(
              color:
                  isDark ? AppColors.darkGlassBorder : AppColors.glassBorder,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark
                      ? AppColors.darkForeground
                      : AppColors.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
