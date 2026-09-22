import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _shareLocation = true;
  bool _shareActivity = true;
  bool _personalizedAds = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Privacy'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PrivacyTile(
                  icon: Icons.location_on_rounded,
                  label: 'Location sharing',
                  subtitle: 'Allow OPOOBO to use your location for trips',
                  value: _shareLocation,
                  onChanged: (v) => setState(() => _shareLocation = v),
                  isDark: isDark,
                ),
                _PrivacyTile(
                  icon: Icons.analytics_rounded,
                  label: 'Usage analytics',
                  subtitle: 'Help improve OPOOBO by sharing anonymous data',
                  value: _shareActivity,
                  onChanged: (v) => setState(() => _shareActivity = v),
                  isDark: isDark,
                ),
                _PrivacyTile(
                  icon: Icons.campaign_rounded,
                  label: 'Personalized recommendations',
                  subtitle: 'Get suggestions based on your activity',
                  value: _personalizedAds,
                  onChanged: (v) => setState(() => _personalizedAds = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Text(
                  'DATA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                _LinkTile(
                  icon: Icons.download_rounded,
                  label: 'Download my data',
                  isDark: isDark,
                  onTap: () => _showDataDialog(context, 'Download'),
                ),
                _LinkTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete my account',
                  isDark: isDark,
                  color: AppColors.destructive,
                  onTap: () => _showDataDialog(context, 'Delete'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your privacy is important to us. We never sell your personal data to third parties.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDataDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('$action my data'),
        content: Text(
          action == 'Download'
              ? 'Your data export will be prepared and sent to your email within 48 hours.'
              : 'This action is permanent and cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              action == 'Download' ? 'Request' : 'Delete',
              style: TextStyle(
                color: action == 'Download'
                    ? AppColors.primary
                    : AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _PrivacyTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.isDark,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.foreground;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
