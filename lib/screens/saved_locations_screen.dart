import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/saved_location_provider.dart';
import '../models/user_models.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedLocationProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<SavedLocationProvider>();
    final locations = provider.locations;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Saved Locations'),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : locations.isEmpty
                    ? _EmptyState(isDark: isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: locations.length,
                        itemBuilder: (ctx, i) => _LocationTile(
                          location: locations[i],
                          isDark: isDark,
                          onDelete: () => _removeLocation(locations[i].id),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_outlined, color: Colors.white),
      ),
    );
  }

  Future<void> _removeLocation(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete location?'),
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
      await context.read<SavedLocationProvider>().remove(id);
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String selectedType = 'bus_stop';
    final codeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Murtala Muhammed Airport)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'airport', child: Text('Airport')),
                    DropdownMenuItem(value: 'bus_stop', child: Text('Bus Stop')),
                    DropdownMenuItem(value: 'terminal', child: Text('Terminal')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'bus_stop'),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (optional, e.g. LOS)')),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address (optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  await context.read<SavedLocationProvider>().add(
                    name: nameCtrl.text,
                    type: selectedType,
                    code: codeCtrl.text.isNotEmpty ? codeCtrl.text : null,
                    address: addressCtrl.text.isNotEmpty ? addressCtrl.text : null,
                  );
                  if (mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
          Icon(Icons.location_off_outlined, size: 64, color: AppColors.mutedForeground),
          const SizedBox(height: 12),
          Text('No saved locations', style: GoogleFonts.inter(fontSize: 15, color: AppColors.mutedForeground)),
          const SizedBox(height: 4),
          Text('Tap + to save your first location', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final SavedLocationData location;
  final bool isDark;
  final VoidCallback? onDelete;

  const _LocationTile({required this.location, required this.isDark, this.onDelete});

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
            child: Icon(
              location.type == 'airport' ? Icons.flight_takeoff_outlined : Icons.directions_bus_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                if (location.code != null && location.code!.isNotEmpty)
                  Text(location.code!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
