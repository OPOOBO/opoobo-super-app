import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/module_provider.dart';
import '../widgets/screen_header.dart';
import '../utils/navigation.dart';

enum ModuleRegistrationMode { link, create }

// Fields already known from the OPOOBO user record — the user
// never has to re-enter these.
const Set<String> _knownFields = {'name', 'email', 'password'};

class ModuleRegistrationScreen extends StatefulWidget {
  final ModuleData module;
  final String? existingEmail;

  const ModuleRegistrationScreen({
    super.key,
    required this.module,
    this.existingEmail,
  });

  @override
  State<ModuleRegistrationScreen> createState() =>
      _ModuleRegistrationScreenState();
}

class _ModuleRegistrationScreenState extends State<ModuleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = false;
  String? _error;

  ModuleRegistrationMode? _mode;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkExisting());
  }

  void _initControllers() {
    // Password is needed when linking an existing module account,
    // or when creating when we don't have the OPOOBO password in memory.
    _controllers['password'] = TextEditingController();

    final requiredFields = widget.module.requiredFields ?? [];
    for (final field in requiredFields) {
      if (!_knownFields.contains(field)) {
        _controllers[field] = TextEditingController();
      }
    }
  }

  Future<void> _checkExisting() async {
    final auth = context.read<AuthProvider>();
    final results = await context.read<ModuleProvider>().checkEmail(
      email: auth.displayEmail,
    );

    if (!mounted) return;

    final result = results.firstWhere(
      (r) => r.module == widget.module.name,
      orElse: () => EmailCheckResult(
        module: widget.module.name,
        displayName: widget.module.displayName,
        exists: false,
      ),
    );

    setState(() {
      _mode = result.exists
          ? ModuleRegistrationMode.link
          : ModuleRegistrationMode.create;
      _checking = false;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isCreateMode => _mode == ModuleRegistrationMode.create;

  String get _passwordValue => _controllers['password']?.text ?? '';

  String _getFieldLabel(String field) {
    switch (field) {
      case 'mobile':
        return 'Phone Number';
      case 'ccode':
        return 'Country Code';
      case 'address':
        return 'Delivery Address';
      case 'city':
        return 'City';
      case 'state':
        return 'State';
      default:
        return field[0].toUpperCase() + field.substring(1).replaceAll('_', ' ');
    }
  }

  String _getFieldHint(String field) {
    switch (field) {
      case 'mobile':
        return 'e.g. 8012345678';
      case 'ccode':
        return 'e.g. +234';
      case 'address':
        return 'Enter your address';
      case 'city':
        return 'Enter your city';
      case 'state':
        return 'Enter your state';
      default:
        return 'Enter ${_getFieldLabel(field).toLowerCase()}';
    }
  }

  TextInputType _getFieldKeyboardType(String field) {
    switch (field) {
      case 'mobile':
        return TextInputType.phone;
      case 'ccode':
        return TextInputType.phone;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'mobile':
        return Icons.phone_rounded;
      case 'ccode':
        return Icons.flag_rounded;
      case 'address':
        return Icons.home_rounded;
      case 'city':
        return Icons.location_city_rounded;
      case 'state':
        return Icons.map_rounded;
      case 'password':
        return Icons.lock_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final moduleProvider = context.read<ModuleProvider>();
    final auth = context.read<AuthProvider>();
    final created = _isCreateMode;

    var linked = false;
    if (!created) {
      // Link an existing module account — verify with its password.
      linked = await moduleProvider.linkModule(
        moduleName: widget.module.name,
        email: auth.displayEmail,
        password: _passwordValue,
      );
    }

    if (!linked) {
      // Create a new module account — name/email come from OPOOBO
      // automatically; only the module-specific fields are collected here.
      final extraFields = <String, dynamic>{'password': _passwordValue};

      for (final entry in _controllers.entries) {
        if (entry.key != 'password') {
          extraFields[entry.key] = entry.value.text;
        }
      }

      final createdOk = await moduleProvider.createModuleAccount(
        moduleName: widget.module.name,
        extraFields: extraFields,
      );

      if (!createdOk) {
        setState(() {
          _loading = false;
          _error = moduleProvider.errorMessage;
        });
        return;
      }
    }

    await _handleModuleLinked(moduleProvider, created: created);
  }

  Future<void> _handleModuleLinked(
    ModuleProvider moduleProvider, {
    required bool created,
  }) async {
    if (!mounted) return;

    // When linking an EXISTING module account, offer to unify its
    // password with the OPOOBO password.
    if (!created && widget.module.canUpdatePassword) {
      final unifiedPassword = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            _PasswordUnifyDialog(moduleName: widget.module.displayName),
      );

      if (unifiedPassword != null && unifiedPassword.isNotEmpty && mounted) {
        final unified = await moduleProvider.updateModulePassword(
          moduleName: widget.module.name,
          newPassword: unifiedPassword,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unified
                    ? 'Passwords unified! ${widget.module.displayName} now uses your OPOOBO password.'
                    : 'Could not update ${widget.module.displayName} password.',
              ),
              backgroundColor: unified ? Colors.green : AppColors.destructive,
            ),
          );
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? '${widget.module.displayName} account created and linked!'
              : '${widget.module.displayName} linked successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
    NavigationHelper.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.read<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: isDark ? AppColors.darkBackground : AppColors.background,
        child: Column(
          children: [
            ScreenHeader(
              title: widget.module.displayName,
              subtitle: _checking
                  ? 'Checking your accounts…'
                  : _isCreateMode
                  ? 'Complete your ${widget.module.displayName} registration'
                  : 'Enter your credentials to link your account',
            ),
            Expanded(
              child: _checking
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoCard(isDark),
                            const SizedBox(height: 24),

                            // Email (read-only from OPOOBO)
                            _buildReadOnlyField(
                              isDark,
                              label: 'Email',
                              value: auth.displayEmail,
                              icon: Icons.email_rounded,
                            ),
                            const SizedBox(height: 16),

                            // Password field — always needed since SSO
                            // doesn't provide plain passwords.
                            if (_mode == ModuleRegistrationMode.link ||
                                true) ...[
                              _buildTextField(
                                isDark,
                                controller: _controllers['password']!,
                                label: _isCreateMode
                                    ? 'OPOOBO Password'
                                    : 'Password',
                                hint: _isCreateMode
                                    ? 'Confirm your password to create your account'
                                    : 'Enter your ${widget.module.displayName} password',
                                icon: Icons.lock_rounded,
                                obscureText: true,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Password is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Dynamic required fields (e.g. phone + country code
                            // for bus) — only shown in create mode.
                            if (_isCreateMode) ...[
                              ..._buildRequiredFields(isDark),
                            ],

                            // Error message
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: _loading
                                        ? null
                                        : AppColors.gradientPrimary,
                                    color: _loading ? Colors.grey : null,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: _loading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.45),
                                              blurRadius: 34,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                  ),
                                  alignment: Alignment.center,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          _isCreateMode
                                              ? 'Create Account'
                                              : 'Link Account',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Skip for now
                            Center(
                              child: TextButton(
                                onPressed: () => NavigationHelper.pop(context),
                                child: Text(
                                  'Skip for now',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkMutedForeground
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCreateMode
                      ? 'Create your ${widget.module.displayName} account'
                      : 'Link your ${widget.module.displayName} account',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isCreateMode
                      ? 'Using your OPOOBO details. Just fill in the missing information.'
                      : 'Use your existing ${widget.module.displayName} credentials to link.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(
    bool isDark, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.5,
        ),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    bool isDark, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkForeground : AppColors.foreground,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: (isDark ? AppColors.darkSurface : AppColors.surface)
            .withValues(alpha: 0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  List<Widget> _buildRequiredFields(bool isDark) {
    final requiredFields = widget.module.requiredFields ?? [];
    final fields = <Widget>[];

    for (final field in requiredFields) {
      if (_knownFields.contains(field)) continue; // Already known from OPOOBO

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildTextField(
            isDark,
            controller: _controllers[field]!,
            label: _getFieldLabel(field),
            hint: _getFieldHint(field),
            icon: _getFieldIcon(field),
            keyboardType: _getFieldKeyboardType(field),
            validator: (v) => v == null || v.isEmpty
                ? '${_getFieldLabel(field)} is required'
                : null,
          ),
        ),
      );
    }

    return fields;
  }
}

class _PasswordUnifyDialog extends StatefulWidget {
  final String moduleName;

  const _PasswordUnifyDialog({required this.moduleName});

  @override
  State<_PasswordUnifyDialog> createState() => _PasswordUnifyDialogState();
}

class _PasswordUnifyDialogState extends State<_PasswordUnifyDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.sync_lock_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use one password everywhere?',
              style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkForeground : AppColors.foreground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Set your OPOOBO password as your ${widget.moduleName} password so you never forget a login.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Enter your OPOOBO password',
                prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor:
                    (isDark ? AppColors.darkSurface : AppColors.secondary)
                        .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), // Keep separate
                    child: Text(
                      'Keep separate',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final password = _passwordController.text.trim();
                      if (password.isEmpty) return;
                      Navigator.pop(context, password);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: null,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Unify passwords',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
