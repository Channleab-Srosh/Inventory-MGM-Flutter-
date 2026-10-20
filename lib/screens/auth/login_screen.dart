import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_components.dart';
import '../../data/api_service.dart';
import 'widgets/forgot_password_dialog.dart';

/// Feature 5 & 8: Professional Login Screen with Loading and Error States
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl =
      TextEditingController(text: AppConstants.defaultAdminUsername);
  final _passCtrl =
      TextEditingController(text: AppConstants.defaultAdminPassword);
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) {
      await Future.wait([
        context.read<CategoryProvider>().fetchCategories(),
        context.read<SupplierProvider>().fetchSuppliers(),
        context.read<ProductProvider>().fetchProducts(),
        context.read<StockProvider>().fetchMovements(),
      ]);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _showForgotPasswordDialog() {
    ForgotPasswordDialog.show(
      context,
      initialInput: _emailCtrl.text.trim(),
      onPasswordReset: (email, newPassword) {
        setState(() {
          _emailCtrl.text = email;
          _passCtrl.text = newPassword;
        });
      },
    );
  }

  void _showServerConfigDialog() {
    final api = ApiService();
    final urlCtrl = TextEditingController(text: api.baseUrl);
    bool isTesting = false;
    bool? testSuccess;
    String? testMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Backend Server URL', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a preset or enter your backend server address:',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'http://192.168.0.242:8080/api/v1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Wi-Fi (192.168.0.242)', style: TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.wifi, size: 14),
                      onPressed: () {
                        setDialogState(() {
                          urlCtrl.text = 'http://192.168.0.242:8080/api/v1';
                          testSuccess = null;
                          testMessage = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Localhost (adb reverse)', style: TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.usb, size: 14),
                      onPressed: () {
                        setDialogState(() {
                          urlCtrl.text = 'http://localhost:8080/api/v1';
                          testSuccess = null;
                          testMessage = null;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.phone_android, size: 14),
                      onPressed: () {
                        setDialogState(() {
                          urlCtrl.text = 'http://10.0.2.2:8080/api/v1';
                          testSuccess = null;
                          testMessage = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              setDialogState(() {
                                isTesting = true;
                                testMessage = null;
                              });
                              final target = urlCtrl.text.trim();
                              final ok = await api.checkConnection(target);
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = ok;
                                testMessage = ok
                                    ? 'Connected successfully!'
                                    : 'Cannot connect to server. Check IP and port.';
                              });
                            },
                      icon: isTesting
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check, size: 14),
                      label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              setDialogState(() {
                                isTesting = true;
                                testMessage = null;
                              });
                              final found = await api.findWorkingBaseUrl();
                              setDialogState(() {
                                isTesting = false;
                                if (found != null) {
                                  urlCtrl.text = found;
                                  testSuccess = true;
                                  testMessage = 'Auto-detected working server!';
                                } else {
                                  testSuccess = false;
                                  testMessage = 'Could not find an active server automatically.';
                                }
                              });
                            },
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('Auto-Detect', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (testMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (testSuccess == true ? AppColors.inStock : AppColors.danger)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess == true ? Icons.check_circle : Icons.error,
                          size: 14,
                          color: testSuccess == true ? AppColors.inStock : AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testMessage!,
                            style: TextStyle(
                              fontSize: 11,
                              color: testSuccess == true ? AppColors.inStock : AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newUrl = urlCtrl.text.trim();
                if (newUrl.isNotEmpty) {
                  await api.setBaseUrl(newUrl);
                  if (mounted) {
                    context.read<AuthProvider>().clearError();
                    setState(() {});
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ResponsiveContainer(
              maxWidth: 440,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Titles
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Inventory Management',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smart inventory control for your business.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Alert (Feature 8)
                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (auth.error!.contains('Unable to connect')) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final discovered = await ApiService().findWorkingBaseUrl();
                                      if (discovered != null && mounted) {
                                        setState(() {});
                                        auth.clearError();
                                        _login();
                                      } else {
                                        _showServerConfigDialog();
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    icon: const Icon(Icons.autorenew, size: 14),
                                    label: const Text('Auto-Detect & Retry', style: TextStyle(fontSize: 11)),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showServerConfigDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: const Size(0, 30),
                                    ),
                                    icon: const Icon(Icons.tune, size: 14),
                                    label: const Text('Change Server IP', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email / Username Field
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Username or Email',
                        hintText: 'Enter your email or username',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username or email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Minimum 6 characters required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign In Button
                    AppButton(
                      label: 'Sign In',
                      onPressed: auth.loading ? null : _login,
                      isLoading: auth.loading,
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: theme.textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: theme.textTheme.bodyMedium?.fontSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Demo Credentials Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Demo Credentials',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _emailCtrl.text = AppConstants.defaultAdminUsername;
                                _passCtrl.text = AppConstants.defaultAdminPassword;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Admin: admin / Admin@12345 (Tap to fill)',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _emailCtrl.text = AppConstants.defaultStaffUsername;
                                _passCtrl.text = AppConstants.defaultStaffPassword;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Staff: staff / Staff@12345 (Tap to fill)',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Server URL Configuration Action
                    Center(
                      child: InkWell(
                        onTap: _showServerConfigDialog,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dns_outlined, size: 14, color: AppColors.grey500),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Server: ${ApiService().baseUrl}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: AppColors.grey500, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

