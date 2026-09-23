import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/module_api_client.dart';
import '../providers/module_provider.dart';
import '../theme/app_colors.dart';
import '../screens/mini_app_screen.dart';
import '../utils/navigation.dart';
import '../widgets/screen_header.dart';

class MiniAppDetailScreen extends StatefulWidget {
  final ModuleData module;

  const MiniAppDetailScreen({super.key, required this.module});

  @override
  State<MiniAppDetailScreen> createState() => _MiniAppDetailScreenState();
}

class _MiniAppDetailScreenState extends State<MiniAppDetailScreen> {
  final ModuleApiClient _api = ModuleApiClient();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final res = await _api.storeDetail(widget.module.id);
      if (res['success'] == true) {
        setState(() {
          _detail = res['data'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to server';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final m = widget.module;
    final detail = _detail ?? {};
    final screenshots = List<String>.from(detail['screenshots'] ?? []);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          ScreenHeader(title: m.displayName, showBack: true),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError(isDark)
                    : _buildContent(isDark, m, screenshots, detail),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48,
              color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
          const SizedBox(height: 12),
          Text(_error!, style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground)),
          const SizedBox(height: 16),
          TextButton(onPressed: _loadDetail, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, ModuleData m, List<String> screenshots, Map<String, dynamic> detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon and info
          Row(
            children: [
              _buildIcon(m, 64, 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkForeground : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (m.developerName != null)
                      Text(
                        m.developerName!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'v${m.version ?? '1.0.0'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Install count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.glass,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.download_outlined, size: 16,
                    color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                const SizedBox(width: 6),
                Text(
                  '${_formatCount(m.installCount)} installs',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkForeground : AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Compliance badges
          _buildComplianceSection(isDark, detail),
          const SizedBox(height: 20),

          // Description
          Text(
            'About',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            m.description ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Screenshots
          if (screenshots.isNotEmpty) ...[
            Text(
              'Screenshots',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: screenshots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    screenshots[i],
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 120,
                      height: 200,
                      color: isDark ? AppColors.darkSurface : AppColors.secondary,
                      child: Icon(Icons.image_outlined,
                          color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Open button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _openApp(m),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Open App',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceSection(bool isDark, Map<String, dynamic> detail) {
    final sslValid = detail['ssl_valid'] ?? false;
    final urlLoads = detail['url_loads'] ?? false;
    final preflightStatus = detail['last_preflight_status'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.glass,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          _buildComplianceRow('HTTPS', sslValid, isDark),
          const SizedBox(height: 6),
          _buildComplianceRow('Loads correctly', urlLoads, isDark),
          const SizedBox(height: 6),
          _buildComplianceRow(
            'Reviewed',
            preflightStatus == 'approved' || preflightStatus == 'passed',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceRow(String label, bool passed, bool isDark) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_outlined : Icons.cancel_outlined,
          size: 16,
          color: passed ? const Color(0xFF2D9F6F) : const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(ModuleData app, double size, double radius) {
    if (app.iconPath != null && app.iconPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          app.iconPath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildDefaultIcon(app, size, radius),
        ),
      );
    }
    return _buildDefaultIcon(app, size, radius);
  }

  Widget _buildDefaultIcon(ModuleData app, double size, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(_getIcon(app.icon), color: AppColors.primary, size: size * 0.52),
    );
  }

  void _openApp(ModuleData app) {
    NavigationHelper.push(context, MiniAppScreen(module: app));
    _api.storeInstall(app.id).catchError((_) => <String, dynamic>{});
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'directions_bus_rounded': return Icons.directions_bus_outlined;
      case 'shopping_cart_rounded': return Icons.shopping_cart_outlined;
      case 'directions_car_rounded': return Icons.directions_car_outlined;
      case 'storefront_rounded': return Icons.storefront_outlined;
      case 'account_balance_wallet_rounded': return Icons.account_balance_wallet_outlined;
      case 'card_giftcard_rounded': return Icons.card_giftcard_outlined;
      case 'play_circle_outline_rounded': return Icons.play_circle_outline_outlined;
      case 'work_outline_rounded': return Icons.work_outline_outlined;
      default: return Icons.widgets_outlined;
    }
  }
}
