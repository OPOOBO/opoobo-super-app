import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/security_provider.dart';
import '../models/user_models.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometrics = false;
  bool _twoFactor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<SecurityProvider>();
    final sessions = provider.sessions;
    final current = provider.currentSession;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Security Settings'),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SecurityTile(
                        icon: Icons.fingerprint_outlined,
                        label: 'Biometric login',
                        subtitle: 'Use fingerprint or face to sign in',
                        trailing: Switch(
                          value: _biometrics,
                          onChanged: (v) => setState(() => _biometrics = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        isDark: isDark,
                      ),
                      _SecurityTile(
                        icon: Icons.security_outlined,
                        label: 'Two-factor authentication',
                        subtitle: 'Add an extra layer of security',
                        trailing: Switch(
                          value: _twoFactor,
                          onChanged: (v) => setState(() => _twoFactor = v),
                          activeThumbColor: AppColors.primary,
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(label: 'SESSIONS', isDark: isDark),
                      if (current != null)
                        _SecurityTile(
                          icon: Icons.phone_android_outlined,
                          label: current.deviceLabel,
                          subtitle: '${current.location ?? "Unknown location"} \u00b7 Current session',
                          badge: 'Current',
                          isDark: isDark,
                        ),
                      ...sessions.where((s) => !s.isCurrent).map(
                        (s) => _SecurityTile(
                          icon: s.deviceType == 'desktop'
                              ? Icons.laptop_mac_outlined
                              : Icons.phone_android_outlined,
                          label: s.deviceLabel,
                          subtitle: [
                            if (s.location != null) s.location,
                            if (s.lastActiveAt != null)
                              'Last active ${_timeAgo(s.lastActiveAt!)}',
                          ].join(' \u00b7 '),
                          trailingIcon: Icons.logout_outlined,
                          isDark: isDark,
                          onTap: () => _revokeSession(s),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(label: 'AUTHENTICATION', isDark: isDark),
                      _SecurityTile(
                        icon: Icons.key_outlined,
                        label: 'Change password',
                        isDark: isDark,
                        onTap: () => _showComingSoon('Change password'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('$feature coming soon'),
        content: Text('$feature will be available in the next update.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _revokeSession(LoginSessionData session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Log out from ${session.deviceLabel}?'),
        content: const Text('You\'ll need to sign in again on that device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<SecurityProvider>().revokeSession(session.id);
    }
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Widget? trailing;
  final IconData? trailingIcon;
  final bool isDark;
  final VoidCallback? onTap;

  const _SecurityTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.trailing,
    this.trailingIcon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: [
                      Flexible(child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(badge!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailingIcon != null)
              Icon(trailingIcon, size: 20, color: AppColors.mutedForeground),
            if (trailing == null && trailingIcon == null && onTap != null)
              Icon(Icons.chevron_right_outlined, size: 20, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.mutedForeground),
      ),
    );
  }
}
