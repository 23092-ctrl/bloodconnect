import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/blood_type_badge.dart';

class DonationsPage extends StatelessWidget {
  const DonationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final role = auth.user!.role;
    if (role == 'center_admin' || role == 'admin') {
      return const _CenterRequestsPage();
    }
    return const _DonorRequestsPage();
  }
}

// ─── STATUS HELPERS ────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.normalGreen;
    case 'completed':
      return const Color(0xFF1565C0);
    case 'rejected':
    case 'cancelled':
      return AppColors.criticalRed;
    default:
      return const Color(0xFFF57C00); // pending = orange
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'confirmed':
      return Icons.check_circle_outline;
    case 'completed':
      return Icons.bloodtype;
    case 'rejected':
      return Icons.cancel_outlined;
    case 'cancelled':
      return Icons.cancel_outlined;
    default:
      return Icons.hourglass_empty;
  }
}

// ─── DONOR VIEW ────────────────────────────────────────────────────────────

class _DonorRequestsPage extends StatefulWidget {
  const _DonorRequestsPage();

  @override
  State<_DonorRequestsPage> createState() => _DonorRequestsPageState();
}

class _DonorRequestsPageState extends State<_DonorRequestsPage> {
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.myAppointments);
      if (!mounted) return;
      setState(() {
        _requests = res.data['data'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(String id) async {
    try {
      await ApiClient.instance.patch('${ApiEndpoints.appointments}/$id/cancel', data: {});
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not cancel request'),
          backgroundColor: AppColors.criticalRed,
        ),
      );
    }
  }

  void _openNewRequestForm() {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) return;
    final user = auth.user!;

    if (!user.medicallyEligible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You are not medically eligible to donate at this time. Please contact your center.'),
          backgroundColor: AppColors.criticalRed,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final days = user.daysSinceLastDonation;
    if (days != null && days < 56) {
      final daysLeft = 56 - days;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You must wait $daysLeft more day${daysLeft > 1 ? 's' : ''} before donating again.'),
          backgroundColor: AppColors.lowOrange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final donorBloodType = user.bloodType;
    if (donorBloodType == null || donorBloodType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Please set your blood type in your profile before submitting a request.'),
          backgroundColor: AppColors.lowOrange,
          action: SnackBarAction(
            label: 'Go to Profile',
            textColor: Colors.white,
            onPressed: () => context.go('/profile'),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewRequestSheet(
        onSuccess: _load,
        defaultBloodType: donorBloodType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequestForm,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.bloodtype_outlined, size: 64, color: AppColors.divider),
                              SizedBox(height: 16),
                              Text('No donation requests yet',
                                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                              SizedBox(height: 8),
                              Text('Tap + to submit a new request',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                      itemCount: _requests.length,
                      itemBuilder: (_, i) => _DonorRequestCard(
                        request: _requests[i],
                        onCancel: () => _cancel(_requests[i]['_id']),
                      ),
                    ),
            ),
    );
  }
}

class _DonorRequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onCancel;

  const _DonorRequestCard({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final center = request['centerId'];
    final centerName =
        center is Map ? (center['name'] ?? 'Blood Center') : 'Blood Center';
    final centerAddress =
        center is Map && center['address'] is Map ? (center['address']['city'] ?? '') : '';
    final createdAt = DateTime.tryParse(request['createdAt'] ?? '');
    final scheduled = request['scheduledDate'] != null
        ? DateTime.tryParse(request['scheduledDate'])
        : null;
    final canCancel = status == 'pending' || status == 'confirmed';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BloodTypeBadge(bloodType: request['bloodType'] ?? '?'),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(centerName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (centerAddress.isNotEmpty)
                        Text(centerAddress,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            if (scheduled != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled: ${DateFormat('MMM dd, yyyy – HH:mm').format(scheduled)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  createdAt != null
                      ? 'Submitted ${DateFormat('MMM dd, yyyy').format(createdAt)}'
                      : '',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (request['autoConfirmed'] == true)
                  const Chip(
                    label: Text('Auto-confirmed',
                        style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Color(0xFFE3F2FD),
                  ),
              ],
            ),
            if (request['rejectionReason'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${request['rejectionReason']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.criticalRed,
                    fontStyle: FontStyle.italic),
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.textSecondary),
                  label: const Text('Cancel Request',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── NEW REQUEST BOTTOM SHEET ──────────────────────────────────────────────

class _NewRequestSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final String? defaultBloodType;
  const _NewRequestSheet({required this.onSuccess, this.defaultBloodType});

  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  List<dynamic> _centers = [];
  String? _selectedCenterId;
  late String _bloodType;
  DateTime? _scheduledDate;
  final _notesCtrl = TextEditingController();
  bool _loadingCenters = true;
  bool _submitting = false;
  String? _error;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _bloodType = widget.defaultBloodType ?? 'O+';
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.bloodCenters);
      final centers =
          res.data['data']['centers'] as List? ?? res.data['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _centers = centers;
        _loadingCenters = false;
        if (centers.isNotEmpty) {
          _selectedCenterId = centers[0]['_id'];
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCenters = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _scheduledDate =
          DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_selectedCenterId == null) {
      setState(() => _error = 'Please select a blood center');
      return;
    }
    setState(() { _submitting = true; _error = null; });

    try {
      await ApiClient.instance.post(ApiEndpoints.appointments, data: {
        'centerId': _selectedCenterId,
        'bloodType': _bloodType,
        if (_scheduledDate != null) 'scheduledDate': _scheduledDate!.toIso8601String(),
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted! Wait for center confirmation.'),
          backgroundColor: AppColors.normalGreen,
        ),
      );
    } catch (e) {
      String msg = 'Failed to submit request. Please try again.';
      final resp = (e is DioException) ? e.response?.data : null;
      if (resp != null) {
        final raw = resp['message'];
        final serverMsg = raw is Map
            ? (raw['message'] as String? ?? '')
            : (raw as String? ?? '');
        if (serverMsg.isNotEmpty) msg = serverMsg;
      }
      setState(() { _error = msg; _submitting = false; });
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
                const Icon(Icons.bloodtype, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('New Donation Request',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingCenters)
              const Center(child: CircularProgressIndicator())
            else if (_centers.isEmpty)
              const Text('No blood centers available',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              DropdownButtonFormField<String>(
                value: _selectedCenterId,
                decoration: const InputDecoration(
                  labelText: 'Blood Center *',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
                items: _centers.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem(
                    value: c['_id'] as String,
                    child: Text(c['name'] as String),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _selectedCenterId = id);
                },
              ),
            const SizedBox(height: 14),
            if (widget.defaultBloodType != null)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Blood Type',
                  prefixIcon: const Icon(Icons.water_drop, color: AppColors.primary),
                  suffixIcon: const Tooltip(
                    message: 'Your blood type from your profile',
                    child: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                  ),
                  filled: true,
                  fillColor: AppColors.primary.withAlpha(15),
                ),
                child: Text(
                  _bloodType,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _bloodType,
                decoration: const InputDecoration(
                  labelText: 'Blood Type *',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
                items: _bloodTypes.map((bt) =>
                    DropdownMenuItem(value: bt, child: Text(bt))).toList(),
                onChanged: (v) => setState(() => _bloodType = v!),
              ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Preferred Date & Time (optional)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _scheduledDate != null
                      ? DateFormat('EEE, MMM dd yyyy – HH:mm')
                          .format(_scheduledDate!)
                      : 'Tap to choose…',
                  style: TextStyle(
                    color: _scheduledDate != null
                        ? AppColors.onBackground
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
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
                onPressed: _submitting || _loadingCenters ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CENTER ADMIN VIEW ─────────────────────────────────────────────────────

class _CenterRequestsPage extends StatefulWidget {
  const _CenterRequestsPage();

  @override
  State<_CenterRequestsPage> createState() => _CenterRequestsPageState();
}

class _CenterRequestsPageState extends State<_CenterRequestsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _centers = [];
  String? _selectedCenterId;
  String? _selectedCenterName;
  List<dynamic> _requests = [];
  bool _loadingCenters = true;
  bool _loadingRequests = false;
  late TabController _tabController;
  int _selectedTab = 0;

  static const _tabs = ['pending', 'confirmed', 'completed', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadCenters();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging || _tabController.index != _selectedTab) {
      setState(() => _selectedTab = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    try {
      final res = await ApiClient.instance.get(ApiEndpoints.bloodCenters);
      final centers =
          res.data['data']['centers'] as List? ?? res.data['data'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _centers = centers;
        _loadingCenters = false;
        if (centers.isNotEmpty) {
          _selectedCenterId = centers[0]['_id'];
          _selectedCenterName = centers[0]['name'];
        }
      });
      if (centers.isNotEmpty) {
        _loadRequests(centers[0]['_id']);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCenters = false);
    }
  }

  Future<void> _loadRequests(String centerId) async {
    setState(() => _loadingRequests = true);
    try {
      final res = await ApiClient.instance
          .get('${ApiEndpoints.appointments}/center/$centerId');
      if (!mounted) return;
      setState(() {
        _requests = (res.data['data'] as List?) ?? [];
        _loadingRequests = false;
        _selectedTab = 0;
        _tabController.index = 0;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _action(String id, String action, {String? reason, String? bloodType}) async {
    try {
      await ApiClient.instance.patch(
        '${ApiEndpoints.appointments}/$id/$action',
        data: reason != null ? {'reason': reason} : {},
      );
      if (!mounted) return;
      _loadRequests(_selectedCenterId!);
      if (action == 'complete') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bloodType != null
                  ? 'Donation recorded. $bloodType stock updated.'
                  : 'Donation recorded. Stock updated.',
            ),
            backgroundColor: AppColors.normalGreen,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('confirmed')
          ? 'Confirm the request first before marking it complete.'
          : 'Action failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.criticalRed),
      );
    }
  }

  void _rejectWithReason(String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _action(id, 'reject',
                  reason: ctrl.text.isNotEmpty ? ctrl.text.trim() : null);
            },
            child: const Text('Reject',
                style: TextStyle(color: AppColors.criticalRed)),
          ),
        ],
      ),
    );
  }

  List<dynamic> _filtered(String status) =>
      _requests.where((r) => r['status'] == status).toList();

  Widget _buildContent() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    final status = _tabs[_selectedTab];
    final items = _filtered(status);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_statusIcon(status), size: 48, color: AppColors.divider),
            const SizedBox(height: 12),
            Text('No $status requests',
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadRequests(_selectedCenterId!),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final req = items[i];
          return _CenterRequestCard(
            request: req,
            onConfirm: () => _action(req['_id'] as String, 'confirm'),
            onComplete: () => _action(req['_id'] as String, 'complete',
                bloodType: req['bloodType'] as String?),
            onReject: () => _rejectWithReason(req['_id'] as String),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Requests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((s) => Tab(
            child: Row(
              children: [
                Icon(_statusIcon(s), size: 16),
                const SizedBox(width: 4),
                Text(s[0].toUpperCase() + s.substring(1)),
                const SizedBox(width: 4),
                if (!_loadingRequests)
                  _CountBadge(count: _filtered(s).length),
              ],
            ),
          )).toList(),
        ),
      ),
      body: _loadingCenters
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_centers.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCenterId,
                      decoration: const InputDecoration(
                        labelText: 'Blood Center',
                        prefixIcon: Icon(Icons.local_hospital),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _centers.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem(
                          value: c['_id'] as String,
                          child: Text(c['name'] as String),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        final c = _centers.firstWhere((x) => x['_id'] == id);
                        setState(() {
                          _selectedCenterId = id;
                          _selectedCenterName = c['name'];
                        });
                        _loadRequests(id);
                      },
                    ),
                  )
                else if (_centers.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    color: AppColors.primary.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCenterName ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }
}

class _CenterRequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onConfirm;
  final VoidCallback onComplete;
  final VoidCallback onReject;

  const _CenterRequestCard({
    required this.request,
    required this.onConfirm,
    required this.onComplete,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = (request['status'] as String?) ?? 'pending';
    final donor = request['donorId'];
    final donorName = donor is Map
        ? ((donor['fullName'] as String?) ?? 'Unknown Donor')
        : 'Unknown Donor';
    final donorEmail =
        donor is Map ? ((donor['email'] as String?) ?? '') : '';
    final donorPhone =
        donor is Map ? ((donor['phone'] as String?) ?? '') : '';
    final notes = request['notes'] as String?;
    final autoConfirmed = request['autoConfirmed'] == true;
    final createdAt =
        DateTime.tryParse((request['createdAt'] as String?) ?? '');
    final scheduled = request['scheduledDate'] != null
        ? DateTime.tryParse(request['scheduledDate'] as String)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Donor info row ───────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                BloodTypeBadge(
                    bloodType: (request['bloodType'] as String?) ?? '?'),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donorName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      if (donorEmail.isNotEmpty)
                        Text(donorEmail,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      if (donorPhone.isNotEmpty)
                        Text(donorPhone,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 8),
            // ── Dates ────────────────────────────────────────────────
            if (scheduled != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Scheduled: ${DateFormat('MMM dd – HH:mm').format(scheduled)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (autoConfirmed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Auto',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ],
                ),
              ),
            if (createdAt != null)
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notes,
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary)),
            ],
            // ── Action buttons ───────────────────────────────────────
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.normalGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'confirmed') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.criticalRed,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.bloodtype, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
