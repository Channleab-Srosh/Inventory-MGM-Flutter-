import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_profile.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable 3-step OTP Password Recovery and Reset Dialog for Administrators
/// Flow:
/// 1. Enter Admin Email -> Generate & Send 6-Digit OTP
/// 2. Enter & Verify 6-Digit OTP (with test autofill helper & resend)
/// 3. Create & Confirm New Password -> Update credentials in AuthProvider
class ForgotPasswordDialog extends StatefulWidget {
  final String initialInput;
  final void Function(String email, String password) onPasswordReset;

  const ForgotPasswordDialog({
    super.key,
    required this.initialInput,
    required this.onPasswordReset,
  });

  /// Static helper to display the dialog easily from any screen
  static Future<void> show(
    BuildContext context, {
    String initialInput = '',
    required void Function(String email, String password) onPasswordReset,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ForgotPasswordDialog(
        initialInput: initialInput,
        onPasswordReset: onPasswordReset,
      ),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _currentStep = 0; // 0: Email, 1: Verify OTP, 2: Reset Password
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  UserProfile? _matchedUser;
  bool _hasChecked = false;
  String? _errorMessage;
  String? _sentOtp;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialInput.trim());

    if (widget.initialInput.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _evaluateUser();
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  UserProfile? _evaluateUser() {
    final query = _emailCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matchedUser = null;
        _hasChecked = false;
        _errorMessage = null;
      });
      return null;
    }

    final auth = context.read<AuthProvider>();
    final user = auth.findUserByEmailOrUsername(query);

    setState(() {
      _matchedUser = user;
      _hasChecked = true;
      if (user == null) {
        _errorMessage = 'No account found with this email.';
      } else if (!user.isAdmin) {
        _errorMessage =
            'Account "${user.name}" is registered as ${user.roleDisplayName}. OTP password reset is strictly reserved for Administrator accounts.';
      } else {
        _errorMessage = null;
      }
    });

    return user;
  }

  // STEP 1: Send OTP to Email
  Future<void> _handleSendOtp({bool isResend = false}) async {
    final user = _evaluateUser();
    if (user == null) {
      setState(() {
        _errorMessage = 'Please enter your administrator email.';
      });
      return;
    }

    if (!user.isAdmin) {
      setState(() {
        _errorMessage =
            'Access Denied: Only Administrator accounts can reset passwords self-service. Please contact your administrator.';
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final otp = await auth.sendOtpToEmail(user.email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (otp != null) {
      setState(() {
        _sentOtp = otp;
        _currentStep = 1;
        _otpCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isResend
                ? 'A new OTP code has been sent to ${user.email}.'
                : 'OTP verification code sent to ${user.email}!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.error ?? 'Failed to send OTP code.';
      });
    }
  }

  // STEP 2: Verify OTP
  void _handleVerifyOtp() {
    final user = _matchedUser;
    if (user == null) return;

    final enteredOtp = _otpCtrl.text.trim();
    if (enteredOtp.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP code.';
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final isValid = auth.verifyOtp(user.email, enteredOtp);

    if (isValid) {
      setState(() {
        _errorMessage = null;
        _currentStep = 2; // Advance to reset password
      });
    } else {
      setState(() {
        _errorMessage = auth.error ?? 'Invalid OTP code. Please try again.';
      });
    }
  }

  // STEP 3: Reset Password
  Future<void> _handleResetPassword() async {
    final user = _matchedUser;
    if (user == null) return;

    if (!_passwordFormKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newPass = _newPasswordCtrl.text;
    final success = await auth.resetPasswordWithOtp(
      emailOrUsername: user.email,
      otp: _otpCtrl.text.trim(),
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      widget.onPasswordReset(user.email, newPass);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Password for admin "${user.name}" reset successfully! You can now sign in.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _errorMessage = auth.error ?? 'Failed to reset password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Title and Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot Password',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'OTP Verification & Password Recovery',
                          style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Step Progress Tracker
              _buildStepIndicator(),
              const SizedBox(height: 16),

              // Active Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content based on Current Step
              Flexible(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildCurrentStepContent(theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'Email', Icons.email_outlined),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: _currentStep >= 1 ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          _buildStepItem(1, 'Verify OTP', Icons.pin_outlined),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: _currentStep >= 2 ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          _buildStepItem(2, 'New Password', Icons.lock_outline),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, IconData icon) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;

    Color color;
    if (isDone) {
      color = AppColors.success;
    } else if (isCurrent) {
      color = AppColors.primary;
    } else {
      color = AppColors.secondaryText;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isDone ? Icons.check_circle : icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Email(theme);
      case 1:
        return _buildStep2Otp(theme);
      case 2:
      default:
        return _buildStep3NewPassword(theme);
    }
  }

  // --- STEP 1: EMAIL & SEND OTP ---
  Widget _buildStep1Email(ThemeData theme) {
    final isBlocked = _matchedUser != null && !_matchedUser!.isAdmin;

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your registered Administrator email address to receive a 6-digit OTP verification code:',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Admin Email',
              hintText: 'admin@inventory.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              suffixIcon: _emailCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _emailCtrl.clear();
                        _evaluateUser();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => _evaluateUser(),
            onFieldSubmitted: (_) => _handleSendOtp(),
          ),
          const SizedBox(height: 12),

          // User evaluation status banner
          if (_hasChecked && _matchedUser != null) ...[
            if (_matchedUser!.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Administrator: ${_matchedUser!.name} (${_matchedUser!.email})',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Account "${_matchedUser!.name}" is registered as ${_matchedUser!.roleDisplayName}.\nOTP password reset is strictly restricted to Administrator accounts. Please contact an administrator.',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ],

          ElevatedButton.icon(
            onPressed: isBlocked || _isLoading ? null : () => _handleSendOtp(),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isLoading ? 'Sending OTP Code...' : 'Send OTP to Email'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: VERIFY OTP ---
  Widget _buildStep2Otp(ThemeData theme) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'We sent a 6-digit OTP code to:\n${_matchedUser?.email ?? _emailCtrl.text}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Change', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Demo OTP code helper banner
          if (_sentOtp != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mark_email_read, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OTP Code: $_sentOtp',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.touch_app, size: 15),
                    label: const Text('Auto-fill', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _otpCtrl.text = _sentOtp!;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // 6-digit OTP input field
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: AppColors.primary,
            ),
            decoration: const InputDecoration(
              labelText: '6-Digit OTP Code',
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(Icons.key_outlined, size: 20),
            ),
            onFieldSubmitted: (_) => _handleVerifyOtp(),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _handleVerifyOtp,
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: const Text('Verify OTP Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
          const SizedBox(height: 10),

          // Resend OTP action
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Didn't receive the OTP? ", style: TextStyle(fontSize: 12)),
              TextButton(
                onPressed: _isLoading ? null : () => _handleSendOtp(isResend: true),
                child: const Text('Resend Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP 3: NEW PASSWORD & RESET ---
  Widget _buildStep3NewPassword(ThemeData theme) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Identity verified for admin "${_matchedUser?.name}". Enter your new password:',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // New Password field
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password *',
              hintText: 'Minimum 6 characters',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a new password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password *',
              hintText: 'Re-enter your new password',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _newPasswordCtrl.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: 16),

          // Submit Reset Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleResetPassword,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock_reset, size: 18),
            label: Text(_isLoading ? 'Updating Password...' : 'Reset Password & Sign In'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ],
      ),
    );
  }
}
