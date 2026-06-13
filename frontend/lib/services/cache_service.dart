import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _box = 'cache';
  static const _summaryKey = 'blood_summary';
  static const _summaryTsKey = 'blood_summary_ts';
  static const _notificationsKey = 'notifications';
  static const _cacheTtlMs = 5 * 60 * 1000; // 5 minutes

  static Future<void> init() async {
    await Hive.openBox(_box);
  }

  static Box get _b => Hive.box(_box);

  // ── Blood summary ─────────────────────────────────────────────────────────

  static Future<void> saveBloodSummary(Map<String, dynamic> data) async {
    await _b.put(_summaryKey, data);
    await _b.put(_summaryTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Map<String, dynamic>? get bloodSummary {
    final raw = _b.get(_summaryKey);
    return raw != null ? Map<String, dynamic>.from(raw) : null;
  }

  static bool get isBloodSummaryFresh {
    final ts = _b.get(_summaryTsKey) as int?;
    if (ts == null) return false;
    return DateTime.now().millisecondsSinceEpoch - ts < _cacheTtlMs;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static Future<void> saveNotifications(List<dynamic> data) async {
    await _b.put(_notificationsKey, data);
  }

  static List<dynamic>? get notifications {
    final raw = _b.get(_notificationsKey);
    return raw != null ? List<dynamic>.from(raw) : null;
  }
}
