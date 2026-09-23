import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_assistant_service.dart';
import '../theme/app_colors.dart';

class ScanScreen extends StatefulWidget {
  final bool active;

  const ScanScreen({super.key, this.active = true});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ImagePicker _picker = ImagePicker();

  _ScanMode _mode = _ScanMode.qr;
  String? _qrValue;
  ProductScanResult? _product;
  String? _productError;
  bool _scanningProduct = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;

    return ColoredBox(
      color: isDark ? AppColors.darkBackground : AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
            child: Row(
              children: [
                Text(
                  'Scan',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                const Spacer(),
                _ModeSwitch(
                  mode: _mode,
                  isDark: isDark,
                  onChanged: (mode) => setState(() => _mode = mode),
                ),
              ],
            ),
          ),
          Expanded(
            child: _mode == _ScanMode.qr
                ? (widget.active
                      ? _buildQr(isDark)
                      : const SizedBox.shrink())
                : _buildProduct(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQr(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: _scanner,
                onDetect: _onQr,
                errorBuilder: (context, error) {
                  return _MessagePane(
                    isDark: isDark,
                    title: 'Camera unavailable',
                    body: error.errorDetails?.message ??
                        'Allow camera access to scan a QR code.',
                  );
                },
              ),
            ),
          ),
        ),
        if (_qrValue != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _ResultCard(
              isDark: isDark,
              title: 'QR code',
              body: _qrValue!,
              actionLabel: _isHttp(_qrValue!) ? 'Open link' : null,
              onAction: _isHttp(_qrValue!) ? () => _open(_qrValue!) : null,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              'Point the camera at a QR code',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProduct(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Take a photo of a product. Ask OPOOBO will describe it and note a price when the model can see one.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.4,
            color: isDark ? AppColors.darkForeground : AppColors.foreground,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _scanningProduct ? null : _captureProduct,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _scanningProduct
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(
              _scanningProduct ? 'Reading photo...' : 'Take product photo',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (_productError != null) ...[
          const SizedBox(height: 16),
          _ResultCard(isDark: isDark, title: 'Unavailable', body: _productError!),
        ],
        if (_product != null) ...[
          const SizedBox(height: 16),
          _ResultCard(
            isDark: isDark,
            title: _product!.name.isEmpty ? 'Product' : _product!.name,
            body: _product!.description.isEmpty
                ? 'No description returned.'
                : _product!.description,
            footer: _product!.priceNote.isEmpty
                ? 'Pricing unavailable'
                : _product!.priceNote,
          ),
        ],
      ],
    );
  }

  void _onQr(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((code) => code.rawValue)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (value == null || value == _qrValue) return;
    setState(() => _qrValue = value);
  }

  Future<void> _captureProduct() async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (shot == null || !mounted) return;

    setState(() {
      _scanningProduct = true;
      _productError = null;
      _product = null;
    });

    try {
      final result = await AiAssistantService().scanProduct(shot.path);
      if (!mounted) return;
      setState(() => _product = result);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _productError = e.message ?? 'Product description is unavailable.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _productError = 'Product description is unavailable.';
      });
    } finally {
      if (mounted) setState(() => _scanningProduct = false);
    }
  }

  bool _isHttp(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

enum _ScanMode { qr, product }

class _ModeSwitch extends StatelessWidget {
  final _ScanMode mode;
  final bool isDark;
  final ValueChanged<_ScanMode> onChanged;

  const _ModeSwitch({
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          _chip('QR', _ScanMode.qr),
          _chip('Product', _ScanMode.product),
        ],
      ),
    );
  }

  Widget _chip(String label, _ScanMode value) {
    final selected = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.mutedForeground),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;
  final String? footer;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ResultCard({
    required this.isDark,
    required this.title,
    required this.body,
    this.footer,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkForeground : AppColors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.4,
              color: isDark
                  ? AppColors.darkMutedForeground
                  : AppColors.secondaryForeground,
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessagePane extends StatelessWidget {
  final bool isDark;
  final String title;
  final String body;

  const _MessagePane({
    required this.isDark,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
