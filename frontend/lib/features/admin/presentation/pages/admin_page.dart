import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/blood_type_badge.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.water_drop), text: 'Inventory'),
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.warning_amber), text: 'Shortages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InventoryTab(),
            _UsersTab(),
            _ShortagesTab(),
          ],
        ),
      ),
    );
  }
}

// ─── INVENTORY TAB ─────────────────────────────────────────────────────────

class _InventoryTab extends StatefulWidget {
  const _InventoryTab();
  @override
  State<_InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<_InventoryTab> {
  List<dynamic> _centers = [];
  String? _selectedCenterId;
  String? _selectedCenterName;
  List<dynamic> _inventory = [];
  bool _loadingCenters = true;
  bool _loadingInventory = false;

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.bloodCenters);
      final centers = res.data['data']['centers'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _centers = centers;
        _loadingCenters = false;
        if (centers.isNotEmpty) {
          _selectedCenterId = centers[0]['_id'];
          _selectedCenterName = centers[0]['name'];
        }
      });
      if (centers.isNotEmpty) _loadInventory(centers[0]['_id']);
    } catch (_) {
      if (mounted) setState(() => _loadingCenters = false);
    }
  }

  Future<void> _loadInventory(String centerId) async {
    setState(() => _loadingInventory = true);
    try {
      final res = await ApiClient.instance
          .get('${ApiEndpoints.bloodInventory}/center/$centerId');
      if (!mounted) return;
      setState(() {
        _inventory = res.data['data'] as List? ?? [];
        _loadingInventory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  void _openUpdateDialog(String bloodType, int currentUnits) {
    final ctrl = TextEditingController(text: '$currentUnits');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Update $bloodType stock'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Available units',
            prefixIcon: Icon(Icons.water_drop_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final units = int.tryParse(ctrl.text.trim());
              if (units == null || units < 0) return;
              Navigator.pop(dialogCtx);
              try {
                await ApiClient.instance.post(
                  '${ApiEndpoints.bloodInventory}/$_selectedCenterId',
                  data: {'bloodType': bloodType, 'availableUnits': units},
                );
                _loadInventory(_selectedCenterId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$bloodType updated to $units units'),
                    backgroundColor: AppColors.normalGreen,
                  ),
                );
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Update failed'),
                    backgroundColor: AppColors.criticalRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? s) => switch (s) {
        'critical' => AppColors.criticalRed,
        'low' => AppColors.lowOrange,
        _ => AppColors.normalGreen,
      };

  @override
  Widget build(BuildContext context) {
    if (_loadingCenters) return const Center(child: CircularProgressIndicator());

    final inventoryMap = {
      for (final e in _inventory) e['bloodType'] as String: e,
    };

    return Column(
      children: [
        if (_centers.length > 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedCenterId,
              decoration: const InputDecoration(
                labelText: 'Blood Center',
                prefixIcon: Icon(Icons.local_hospital),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _centers.map<DropdownMenuItem<String>>((c) =>
                  DropdownMenuItem(value: c['_id'] as String, child: Text(c['name'] as String))).toList(),
              onChanged: (id) {
                if (id == null) return;
                final c = _centers.firstWhere((x) => x['_id'] == id);
                setState(() {
                  _selectedCenterId = id;
                  _selectedCenterName = c['name'];
                });
                _loadInventory(id);
              },
            ),
          )
        else if (_centers.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary.withOpacity(0.08),
            child: Text(
              _selectedCenterName ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        if (_loadingInventory)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadInventory(_selectedCenterId!),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: _bloodTypes.map((bt) {
                  final entry = inventoryMap[bt];
                  final units = entry != null ? (entry['availableUnits'] as num).toInt() : 0;
                  final status = entry?['status'] as String? ?? 'normal';
                  final color = _statusColor(status);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: BloodTypeBadge(bloodType: bt),
                      title: Text('$units units',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(status.toUpperCase(),
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.primary,
                        onPressed: () => _openUpdateDialog(bt, units),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── USERS TAB ──────────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.users);
      if (!mounted) return;
      setState(() {
        _users = res.data['data']['users'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleEligibility(String id, bool current) async {
    try {
      await ApiClient.instance.patch(
        '${ApiEndpoints.users}/$id',
        data: {'medicallyEligible': !current},
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed'), backgroundColor: AppColors.criticalRed),
      );
    }
  }

  void _confirmDeactivate(String id, String name) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Deactivate $name? They will no longer be able to log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ApiClient.instance.delete('${ApiEndpoints.users}/$id');
                _load();
              } catch (_) {}
            },
            child: const Text('Deactivate', style: TextStyle(color: AppColors.criticalRed)),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
        'admin' => AppColors.criticalRed,
        'center_admin' => AppColors.secondary,
        _ => AppColors.normalGreen,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i];
          final role = u['role'] as String? ?? 'donor';
          final eligible = u['medicallyEligible'] as bool? ?? true;
          final active = u['isActive'] as bool? ?? true;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _roleColor(role).withOpacity(0.15),
                        child: Text(
                          (u['fullName'] as String? ?? '?')[0].toUpperCase(),
                          style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['fullName'] as String? ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(u['email'] as String? ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _roleColor(role).withOpacity(0.4)),
                        ),
                        child: Text(role,
                            style: TextStyle(fontSize: 11, color: _roleColor(role), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (role == 'donor') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (u['bloodType'] != null)
                          BloodTypeBadge(bloodType: u['bloodType'] as String),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              eligible ? Icons.check_circle : Icons.cancel,
                              size: 14,
                              color: eligible ? AppColors.normalGreen : AppColors.criticalRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              eligible ? 'Eligible' : 'Not eligible',
                              style: TextStyle(
                                fontSize: 12,
                                color: eligible ? AppColors.normalGreen : AppColors.criticalRed,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: eligible,
                              onChanged: active
                                  ? (_) => _toggleEligibility(u['_id'] as String, eligible)
                                  : null,
                              activeColor: AppColors.normalGreen,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!active)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('DEACTIVATED',
                            style: TextStyle(color: AppColors.criticalRed, fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _confirmDeactivate(u['_id'] as String, u['fullName'] as String? ?? ''),
                          icon: const Icon(Icons.person_off_outlined, size: 14, color: AppColors.textSecondary),
                          label: const Text('Deactivate', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── SHORTAGES TAB ──────────────────────────────────────────────────────────

class _ShortagesTab extends StatefulWidget {
  const _ShortagesTab();
  @override
  State<_ShortagesTab> createState() => _ShortagesTabState();
}

class _ShortagesTabState extends State<_ShortagesTab> {
  List<dynamic> _shortages = [];
  bool _loading = false;
  bool _detecting = false;
  bool _detected = false;

  Future<void> _detect() async {
    setState(() { _detecting = true; _detected = false; });
    try {
      final res = await ApiClient.instance
          .get('${ApiEndpoints.bloodInventory}/shortages/detect');
      if (!mounted) return;
      setState(() {
        _shortages = res.data['data'] as List? ?? [];
        _detecting = false;
        _detected = true;
      });
    } catch (_) {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Color _statusColor(String s) => switch (s) {
        'critical' => AppColors.criticalRed,
        'low' => AppColors.lowOrange,
        _ => AppColors.normalGreen,
      };

  IconData _statusIcon(String s) => switch (s) {
        'critical' => Icons.emergency,
        'low' => Icons.warning_amber,
        _ => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _detecting ? null : _detect,
            icon: _detecting
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
            label: Text(_detecting ? 'Detecting...' : 'Detect Shortages Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The shortage engine runs automatically every 30 min.\nUse this button to trigger a manual detection.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_detected) ...[
            Text(
              _shortages.isEmpty ? 'No shortages detected.' : '${_shortages.length} shortage(s) detected:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _shortages.isEmpty ? AppColors.normalGreen : AppColors.criticalRed,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            ..._shortages.map((s) {
              final status = s['status'] as String? ?? 'low';
              final color = _statusColor(status);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(_statusIcon(status), color: color),
                  ),
                  title: Row(
                    children: [
                      BloodTypeBadge(bloodType: s['bloodType'] as String? ?? '?'),
                      const SizedBox(width: 8),
                      Text(status.toUpperCase(),
                          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(
                    '${s['totalUnits']} units remaining across all centers',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
