import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = [
      {
        'q': 'How do I link my bus account?',
        'a': 'Go to Connected Apps and tap on Bus. Your account is linked automatically using your OPOOBO SSO.',
      },
      {
        'q': 'How do I reset my password?',
        'a': 'OPOOBO uses Keycloak SSO. Tap "Forgot password" on the login screen or go to Security Settings > Change Password.',
      },
      {
        'q': 'How do I add money to my wallet?',
        'a': 'Go to Profile > Payment Methods to top up your OPOOBO Wallet.',
      },
      {
        'q': 'How do I contact support?',
        'a': 'Use the chat button below or email support@opoobo.com. We respond within 24 hours.',
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Help Center'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_outlined,
                        size: 20,
                        color: AppColors.mutedForeground,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Search help topics...',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Quick links
                Text(
                  'QUICK LINKS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                _QuickLink(
                  icon: Icons.chat_bubble_outline_outlined,
                  label: 'Chat with support',
                  isDark: isDark,
                  onTap: () => _showComingSoon(context, 'Live chat'),
                ),
                _QuickLink(
                  icon: Icons.email_outlined,
                  label: 'Email support@opoobo.com',
                  isDark: isDark,
                  onTap: () => launchUrl(
                    Uri.parse('mailto:support@opoobo.com?subject=OPOOBO Support'),
                  ),
                ),
                _QuickLink(
                  icon: Icons.bug_report_outlined,
                  label: 'Report a bug',
                  isDark: isDark,
                  onTap: () => launchUrl(
                    Uri.parse(
                      'mailto:support@opoobo.com?subject=Bug Report&body=Describe the bug...',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // FAQs
                Text(
                  'FREQUENTLY ASKED',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                ...faqs.map((f) => _FaqTile(
                  question: f['q']!,
                  answer: f['a']!,
                  isDark: isDark,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('$feature coming soon'),
      content: Text('$feature will be available in the next update.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
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
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_outlined,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
