import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable modal sheet for adding and editing users (Admin only)
class AddEditUserSheet extends StatefulWidget {
  final UserProfile? user;
  const AddEditUserSheet({super.key, this.user});

  static Future<void> show(BuildContext context, {UserProfile? user}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddEditUserSheet(user: user),
    );
  }

  @override
  State<AddEditUserSheet> createState() => _AddEditUserSheetState();
}

class _AddEditUserSheetState extends State<AddEditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  String _role = 'STAFF';
  String _status = 'Active';

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _usernameCtrl = TextEditingController(text: u?.username ?? '');
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    if (u != null) {
      _role = u.role.toUpperCase();
      _status = u.status;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    final username = _usernameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();

    if (_isEditing) {
      final updated = widget.user!.copyWith(
        username: username,
        name: name,
        email: email,
        phone: phone,
        role: _role,
        status: _status,
      );
      final ok = await auth.updateUser(updated);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User details updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to update user'), backgroundColor: AppColors.danger),
          );
        }
      }
    } else {
      final newUser = UserProfile(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        username: username,
        name: name,
        email: email,
        phone: phone,
        role: _role,
        status: _status,
        createdAt: DateTime.now(),
      );
      final ok = await auth.addUser(newUser);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New user created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to create user'), backgroundColor: AppColors.danger),
          );
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEditing ? 'Edit User' : 'Create New User',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Username
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'e.g. dara or sokha',
                  prefixIcon: Icon(Icons.alternate_email, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required';
                  if (v.trim().length < 3) return 'Minimum 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Dara Chann',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'dara@inventory.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '+855 12 345 678',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Role selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'System Role',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text('ADMIN (Full Access)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'STAFF',
                    child: Text('STAFF (Standard Operations)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
              ),
              const SizedBox(height: 14),

              // Status selector
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Account Status',
                  prefixIcon: Icon(Icons.toggle_on_outlined, size: 20),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Active',
                    child: Text('Active (Can Log In)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Inactive',
                    child: Text('Inactive (Suspended)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEditing ? 'Save Changes' : 'Create User'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

/// Dialog to change a user's system role
class UserRoleDialog {
  static Future<String?> show(BuildContext context, {required UserProfile target}) {
    String selectedRole = target.role.toUpperCase();
    if (selectedRole != 'ADMIN' && selectedRole != 'STAFF') {
      selectedRole = 'STAFF';
    }

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Change User Role'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a new role for "${target.name}":',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: selectedRole,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          value: 'ADMIN',
                          title: Text('ADMIN'),
                          subtitle: Text('Full system access and user management', style: TextStyle(fontSize: 12)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          value: 'STAFF',
                          title: Text('STAFF'),
                          subtitle: Text('Standard inventory operations', style: TextStyle(fontSize: 12)),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, selectedRole),
                child: const Text('Save Role'),
              ),
            ],
          );
        },
      ),
    );
  }
}
