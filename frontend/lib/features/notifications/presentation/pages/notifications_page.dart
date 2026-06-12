import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.notifications);
      final data = response.data['data'];
      setState(() {
        _notifications = data['notifications'] as List;
        _unread = data['unread'] as int;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.patch('${ApiEndpoints.notifications}/read-all');
      setState(() {
        _notifications = _notifications.map((n) => {...n, 'isRead': true}).toList();
        _unread = 0;
      });
    } catch (_) {}
  }

  Future<void> _markRead(String id, int index) async {
    if (_notifications[index]['isRead'] == true) return;
    try {
      await ApiClient.instance.patch('${ApiEndpoints.notifications}/$id/read');
      setState(() {
        _notifications[index] = {..._notifications[index], 'isRead': true};
        if (_unread > 0) _unread--;
      });
    } catch (_) {}
  }

  IconData _typeIcon(String? type) => switch (type) {
        'shortage_alert' => Icons.warning_amber_rounded,
        'reminder' => Icons.alarm,
        'campaign' => Icons.campaign,
        _ => Icons.notifications,
      };

  Color _typeColor(String? type) => switch (type) {
        'shortage_alert' => AppColors.criticalRed,
        'reminder' => AppColors.lowOrange,
        'campaign' => AppColors.secondary,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (_unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unread',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: AppColors.divider),
                          SizedBox(height: 16),
                          Text('No notifications yet',
                              style: TextStyle(
                                  fontSize: 18, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, i) {
                        final n = _notifications[i];
                        final isRead = n['isRead'] == true;
                        final date = DateTime.tryParse(n['createdAt'] ?? '');
                        final type = n['type'] as String?;

                        return ListTile(
                          onTap: () => _markRead(n['_id'], i),
                          tileColor: isRead ? null : AppColors.primary.withOpacity(0.04),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _typeColor(type).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_typeIcon(type),
                                color: _typeColor(type), size: 22),
                          ),
                          title: Text(
                            n['title'] ?? '',
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n['body'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13)),
                              if (date != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, HH:mm').format(date),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: true,
                          trailing: isRead
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        );
                      },
                    ),
            ),
    );
  }
}
