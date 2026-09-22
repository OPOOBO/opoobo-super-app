import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/address_provider.dart';
import '../models/user_models.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AddressProvider>();
    final addresses = provider.addresses;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Addresses'),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : addresses.isEmpty
                    ? _EmptyState(isDark: isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        itemBuilder: (ctx, i) => _AddressTile(
                          address: addresses[i],
                          isDark: isDark,
                          onDelete: () => _removeAddress(addresses[i].id),
                          onSetDefault: () => _setDefault(addresses[i].id),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Future<void> _removeAddress(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AddressProvider>().remove(id);
    }
  }

  Future<void> _setDefault(int id) async {
    await context.read<AddressProvider>().update(id, {'is_default': true});
  }

  void _showAddDialog() {
    final labelCtrl = TextEditingController();
    final line1Ctrl = TextEditingController();
    final line2Ctrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add address'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Home)')),
              TextField(controller: line1Ctrl, decoration: const InputDecoration(labelText: 'Address line 1')),
              TextField(controller: line2Ctrl, decoration: const InputDecoration(labelText: 'Address line 2 (optional)')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (labelCtrl.text.isNotEmpty && line1Ctrl.text.isNotEmpty && cityCtrl.text.isNotEmpty && stateCtrl.text.isNotEmpty) {
                await context.read<AddressProvider>().add(
                  label: labelCtrl.text,
                  addressLine1: line1Ctrl.text,
                  addressLine2: line2Ctrl.text.isNotEmpty ? line2Ctrl.text : null,
                  city: cityCtrl.text,
                  state: stateCtrl.text,
                );
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home_outlined, size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          Text('No addresses yet', style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          Text('Tap + to add your first address', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final AddressData address;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const _AddressTile({
    required this.address,
    required this.isDark,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                        child: Text('Default', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(address.fullAddress, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete?.call();
              if (v == 'default') onSetDefault?.call();
            },
            itemBuilder: (_) => [
              if (!address.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as default')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
