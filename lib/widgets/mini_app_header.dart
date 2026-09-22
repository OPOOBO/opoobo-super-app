import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class MiniAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String moduleName;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final VoidCallback? onOpenInBrowser;
  final VoidCallback? onCopyLink;
  final VoidCallback? onReport;

  const MiniAppHeader({
    super.key,
    required this.moduleName,
    this.onBack,
    this.onRefresh,
    this.onOpenInBrowser,
    this.onCopyLink,
    this.onReport,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: isDark
                ? AppColors.darkMutedForeground
                : AppColors.mutedForeground,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              moduleName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: isDark
                    ? AppColors.darkForeground
                    : AppColors.foreground,
              ),
              onPressed: onRefresh,
            ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
            onSelected: (v) {
              switch (v) {
                case 'browser':
                  onOpenInBrowser?.call();
                  break;
                case 'copy':
                  onCopyLink?.call();
                  break;
                case 'report':
                  onReport?.call();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'browser',
                child: Text('Open in browser'),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Text('Copy link'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report app'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
