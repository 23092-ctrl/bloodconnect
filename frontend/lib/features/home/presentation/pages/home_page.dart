import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/blood_type_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.globalSummary);
      setState(() {
        _summary = Map<String, dynamic>.from(response.data['data']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) => switch (status) {
        'critical' => AppColors.criticalRed,
        'low' => AppColors.lowOrange,
        _ => AppColors.normalGreen,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  title: BlocBuilder<AuthBloc, AuthState>(
                    builder: (_, state) {
                      final name = state is AuthAuthenticated
                          ? state.user.fullName.split(' ').first
                          : 'Donor';
                      return Text('Hello, $name 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 16));
                    },
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.bloodtype, size: 60, color: Colors.white24),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () {
                      if (GoRouterState.of(context).matchedLocation != '/notifications') {
                        context.go('/notifications');
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DonateNowCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'National Blood Stock',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Real-time inventory across all blood banks',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_summary != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final entry = _summary!.entries.toList()[i];
                        final status = entry.value['status'] as String?;
                        final units = entry.value['totalUnits'];
                        return _BloodStockCard(
                          bloodType: entry.key,
                          units: units is int ? units : (units as num).toInt(),
                          status: status ?? 'normal',
                          statusColor: _statusColor(status),
                        );
                      },
                      childCount: _summary!.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonateNowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (_, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final canDonate = user?.canDonate ?? true;

        return Card(
          color: canDonate ? AppColors.primary : AppColors.textSecondary,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canDonate ? 'You can donate today!' : 'Next donation available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        canDonate
                            ? 'Find your nearest blood bank'
                            : 'You donated recently. Thank you!',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (canDonate)
                  ElevatedButton(
                    onPressed: () {
                      if (GoRouterState.of(context).matchedLocation != '/maps') {
                        context.go('/maps');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Donate'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BloodStockCard extends StatelessWidget {
  final String bloodType;
  final int units;
  final String status;
  final Color statusColor;

  const _BloodStockCard({
    required this.bloodType,
    required this.units,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BloodTypeBadge(bloodType: bloodType),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$units units',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
