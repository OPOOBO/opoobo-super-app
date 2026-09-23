import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../widgets/screen_header.dart';
import '../providers/payment_method_provider.dart';
import '../models/user_models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PaymentMethodProvider>();
    final methods = provider.methods;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Column(
        children: [
          const ScreenHeader(title: 'Payment Methods'),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (methods.isEmpty)
                        _EmptyState(isDark: isDark)
                      else
                        ...methods.map((m) => _PaymentCard(
                          method: m,
                          isDark: isDark,
                          onDelete: () => _removeMethod(m.id),
                          onSetDefault: () => _setDefault(m.id),
                        )),
                      const SizedBox(height: 12),
                      _AddButton(
                        label: 'Add card',
                        icon: Icons.credit_card_outlined,
                        isDark: isDark,
                        onTap: () => _showAddCardDialog(),
                      ),
                      const SizedBox(height: 8),
                      _AddButton(
                        label: 'Add bank account',
                        icon: Icons.account_balance_outlined,
                        isDark: isDark,
                        onTap: () => _showAddBankDialog(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'OPOOBO Wallet',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradientPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OPOOBO WALLET',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\u20a60.00',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Top up',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMethod(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<PaymentMethodProvider>().remove(id);
    }
  }

  Future<void> _setDefault(int id) async {
    await context.read<PaymentMethodProvider>().setDefault(id);
  }

  void _showAddCardDialog() {
    final providerNameCtrl = TextEditingController();
    final lastFourCtrl = TextEditingController();
    final expiryMonthCtrl = TextEditingController();
    final expiryYearCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: providerNameCtrl, decoration: const InputDecoration(labelText: 'Card provider (e.g. Visa)')),
            TextField(controller: lastFourCtrl, decoration: const InputDecoration(labelText: 'Last 4 digits'), keyboardType: TextInputType.number),
            Row(
              children: [
                Expanded(child: TextField(controller: expiryMonthCtrl, decoration: const InputDecoration(labelText: 'MM'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: expiryYearCtrl, decoration: const InputDecoration(labelText: 'YY'), keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (providerNameCtrl.text.isNotEmpty && lastFourCtrl.text.isNotEmpty) {
                await context.read<PaymentMethodProvider>().add(
                  type: 'card',
                  provider: providerNameCtrl.text,
                  lastFour: lastFourCtrl.text,
                  expiryMonth: expiryMonthCtrl.text,
                  expiryYear: expiryYearCtrl.text,
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

  void _showAddBankDialog() {
    final bankNameCtrl = TextEditingController();
    final accountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add bank account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank name')),
            TextField(controller: accountCtrl, decoration: const InputDecoration(labelText: 'Account number (last 4)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (bankNameCtrl.text.isNotEmpty && accountCtrl.text.isNotEmpty) {
                await context.read<PaymentMethodProvider>().add(
                  type: 'bank',
                  provider: bankNameCtrl.text,
                  lastFour: accountCtrl.text,
                  bankName: bankNameCtrl.text,
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.credit_card_off_outlined, size: 48, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text('No payment methods', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
            const SizedBox(height: 4),
            Text('Add a card or bank account to get started', style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentMethodData method;
  final bool isDark;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const _PaymentCard({
    required this.method,
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
          color: method.isDefault
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: method.isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (method.type == 'card' ? AppColors.primary : AppColors.success).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              method.type == 'card' ? Icons.credit_card_outlined : Icons.account_balance_outlined,
              color: method.type == 'card' ? AppColors.primary : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(method.displayName, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(6)),
                        child: Text('Default', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                Text(method.subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') onDelete?.call();
              if (v == 'default') onSetDefault?.call();
            },
            itemBuilder: (_) => [
              if (!method.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as default')),
              const PopupMenuItem(value: 'delete', child: Text('Remove')),
            ],
            icon: Icon(Icons.more_vert_outlined, size: 20, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
