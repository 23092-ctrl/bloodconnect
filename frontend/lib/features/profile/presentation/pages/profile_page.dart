import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/blood_type_badge.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  bool _medicallyEligible = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _notificationsEnabled = state.user.notificationsEnabled;
      _medicallyEligible = state.user.medicallyEligible;
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      await ApiClient.instance.patch(ApiEndpoints.me, data: {'notificationsEnabled': value});
      setState(() => _notificationsEnabled = value);
    } catch (_) {}
  }

  void _openEditProfile(UserEntity user) {
    final bloc = context.read<AuthBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        onSuccess: () => bloc.add(AuthProfileUpdated()),
      ),
    );
  }

  void _confirmLogout() {
    final bloc = context.read<AuthBloc>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx); // ferme le dialog avec son propre contexte
              bloc.add(AuthLogoutRequested()); // BlocListener dans main.dart navigue après 300ms
            },
            child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          return ListView(
            children: [
              // Header
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white24,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 36, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.fullName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    if (user.bloodType != null) ...[
                      const SizedBox(height: 12),
                      BloodTypeBadge(bloodType: user.bloodType!, large: true),
                    ],
                  ],
                ),
              ),

              // Donation status
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          user.canDonate ? Icons.check_circle : Icons.schedule,
                          color: user.canDonate ? AppColors.normalGreen : AppColors.lowOrange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.canDonate ? 'Eligible to donate' : 'Not yet eligible',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: user.canDonate
                                      ? AppColors.normalGreen
                                      : AppColors.lowOrange,
                                ),
                              ),
                              if (user.daysSinceLastDonation != null)
                                Text(
                                  user.canDonate
                                      ? 'Last donation: ${user.daysSinceLastDonation} days ago'
                                      : '${56 - user.daysSinceLastDonation!} days until next donation',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.textSecondary),
                                )
                              else
                                const Text('No donation history',
                                    style: TextStyle(
                                        fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Settings
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Settings',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12)),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      title: const Text('Shortage Alerts'),
                      subtitle: const Text('Receive notifications when blood is critically low'),
                      secondary: const Icon(Icons.notifications_outlined),
                      activeColor: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Medical Status'),
                      subtitle: Text(
                        _medicallyEligible ? 'Eligible to donate' : 'Not eligible',
                        style: TextStyle(
                            color: _medicallyEligible
                                ? AppColors.normalGreen
                                : AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Account
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Account',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        fontSize: 12)),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openEditProfile(user),
                    ),
                    const Divider(height: 1, indent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.error),
                      title: const Text('Sign Out',
                          style: TextStyle(color: AppColors.error)),
                      onTap: _confirmLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ─── EDIT PROFILE SHEET ────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserEntity user;
  final VoidCallback onSuccess;

  const _EditProfileSheet({required this.user, required this.onSuccess});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _bloodType;
  String? _gender;
  bool _saving = false;
  String? _error;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _genders = ['male', 'female'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _bloodType = widget.user.bloodType;
    _gender = widget.user.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Full name is required');
      return;
    }
    setState(() { _saving = true; _error = null; });

    try {
      await ApiClient.instance.patch(ApiEndpoints.me, data: {
        'fullName': name,
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_bloodType != null) 'bloodType': _bloodType,
        if (_gender != null) 'gender': _gender,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.normalGreen,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to update profile. Please try again.';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
                hintText: '+222 XX XX XX XX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: const InputDecoration(
                labelText: 'Blood Type',
                prefixIcon: Icon(Icons.water_drop_outlined),
              ),
              hint: const Text('Select blood type'),
              items: _bloodTypes.map((bt) =>
                  DropdownMenuItem(value: bt, child: Text(bt))).toList(),
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              hint: const Text('Select gender'),
              items: _genders.map((g) => DropdownMenuItem(
                value: g,
                child: Text(g[0].toUpperCase() + g.substring(1)),
              )).toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
