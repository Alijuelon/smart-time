import 'dart:async';
import '../db/db_helper.dart';
import '../models/rule_model.dart';
import 'notification_service.dart';

class ViolationChecker {
  final DBHelper dbHelper = DBHelper();
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkViolations();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _checkViolations() async {
    final rules = await dbHelper.getRules();
    final now = DateTime.now();

    for (var rule in rules) {
      final endTime = rule.createdAt.add(
        Duration(minutes: rule.durationMinutes),
      );

      final isExpired = now.isAfter(endTime);
      final notCompleted = !rule.isCompleted;

      if (isExpired && notCompleted && !rule.isViolated) {
        // Update ke status dilanggar
        final violatedRule = Rule(
          id: rule.id,
          name: rule.name,
          durationMinutes: rule.durationMinutes,
          createdAt: rule.createdAt,
          isCompleted: false,
          isViolated: true,
        );
        await dbHelper.updateRule(violatedRule);

        // Kirim notifikasi pelanggaran
        await showViolationNotification(rule.name);
      }
    }
  }
}
