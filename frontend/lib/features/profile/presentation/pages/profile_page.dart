import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/settings_controller.dart';
import '../../../../models/user_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/blood_type_badge.dart';
import '../../../../l10n/app_localizations.dart';

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
    final user = context.read<AuthController>().user;
    if (user != null) {
      _notificationsEnabled = user.notificationsEnabled;
      _medicallyEligible = user.medicallyEligible;
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      await ApiClient.instance
          .patch(ApiEndpoints.me, data: {'notificationsEnabled': value});
      setState(() => _notificationsEnabled = value);
    } catch (_) {}
  }

  void _openEditProfile(UserModel user) {
    final auth = context.read<AuthController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(
        user: user,
        onSuccess: () => auth.refreshProfile(),
      ),
    );
  }

  void _confirmLogout() {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthController>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              auth.logout();
            },
            child: Text(
              l10n.signOut,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        children: [
          Container(
            color: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style:
                        const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                if (user.bloodType != null) ...[
                  const SizedBox(height: 12),
                  BloodTypeBadge(bloodType: user.bloodType!, large: true),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      user.canDonate ? Icons.check_circle : Icons.schedule,
                      color: user.canDonate
                          ? AppColors.normalGreen
                          : AppColors.lowOrange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.canDonate
                                ? l10n.eligibleToDonate
                                : l10n.notYetEligible,
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
                                  ? l10n.lastDonationDaysAgo(
                                      user.daysSinceLastDonation!)
                                  : l10n.daysUntilNextDonation(
                                      56 - user.daysSinceLastDonation!),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            )
                          else
                            Text(
                              l10n.noDonationHistory,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.settings,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  title: Text(l10n.shortageAlerts),
                  subtitle: Text(l10n.shortageAlertsSubtitle),
                  secondary: const Icon(Icons.notifications_outlined),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.medicalStatus),
                  subtitle: Text(
                    _medicallyEligible
                        ? l10n.eligibleToDonate
                        : l10n.notYetEligible,
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
          // ── Apparence ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Apparence',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<SettingsController>(
              builder: (context, settings, _) => Column(
                children: [
                  // Thème clair/sombre
                  SwitchListTile(
                    value: settings.isDark,
                    onChanged: (_) => settings.toggleTheme(),
                    title: const Text('Mode sombre'),
                    secondary: Icon(
                      settings.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(height: 1, indent: 16),
                  // Sélecteur de langue
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.primary),
                    title: const Text('Langue / Language'),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: ['fr', 'en'].map((code) {
                          final selected =
                              settings.locale.languageCode == code;
                          return GestureDetector(
                            onTap: () => settings.setLocale(code),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              l10n.account,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.editProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openEditProfile(user),
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(l10n.signOut,
                      style: const TextStyle(color: AppColors.error)),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
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
    setState(() {
      _saving = true;
      _error = null;
    });
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
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
                Text(l10n.editProfile,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
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
              decoration: InputDecoration(
                labelText: '${l10n.fullName} *',
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: l10n.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: '+222 XX XX XX XX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: InputDecoration(
                labelText: l10n.bloodType,
                prefixIcon: const Icon(Icons.water_drop_outlined),
              ),
              hint: Text(l10n.bloodType),
              items: _bloodTypes
                  .map((bt) => DropdownMenuItem(value: bt, child: Text(bt)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: l10n.gender,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              hint: Text(l10n.gender),
              items: _genders
                  .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g == 'male' ? l10n.male : l10n.female),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: const TextStyle(
                      color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
