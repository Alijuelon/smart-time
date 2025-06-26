import 'package:flutter/material.dart';
import '../models/rule_model.dart';
import '../db/db_helper.dart';
import 'rule_form_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

bool _fabPressed = false;
int _currentIndex = 0;

class RuleListScreen extends StatefulWidget {
  const RuleListScreen({super.key});

  @override
  State<RuleListScreen> createState() => _RuleListScreenState();
}

class _RuleListScreenState extends State<RuleListScreen>
    with SingleTickerProviderStateMixin {
  final dbHelper = DBHelper();
  List<Rule> rules = [];
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchRules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchRules() async {
    setState(() => _isLoading = true);
    final data = await dbHelper.getRules();
    setState(() {
      rules = data;
      _isLoading = false;
    });
  }

  List<Rule> get _activeRules {
    final now = DateTime.now();
    return rules.where((rule) {
      final endTime = rule.createdAt.add(
        Duration(minutes: rule.durationMinutes),
      );
      return !rule.isCompleted && now.isBefore(endTime);
    }).toList();
  }

  List<Rule> get _completedRules =>
      rules.where((rule) => rule.isCompleted).toList();

  List<Rule> get _expiredRules {
    final now = DateTime.now();
    return rules.where((rule) {
      final endTime = rule.createdAt.add(
        Duration(minutes: rule.durationMinutes),
      );
      return !rule.isCompleted && now.isAfter(endTime);
    }).toList();
  }

  void showSnack(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        elevation: 4,
      ),
    );
  }

  void deleteRule(int id) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Hapus Aturan'),
            content: const Text('Yakin ingin menghapus aturan ini?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: TextStyle(color: theme.colorScheme.secondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await dbHelper.deleteRule(id);
      fetchRules();
      showSnack('Aturan berhasil dihapus', color: Colors.red);
    }
  }

  void openForm({Rule? rule}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RuleFormScreen(rule: rule)),
    );
    if (result == true) fetchRules();
  }

  void completeRule(Rule rule) async {
    final endTime = rule.createdAt.add(Duration(minutes: rule.durationMinutes));
    final isExpired = DateTime.now().isAfter(endTime);

    if (rule.isCompleted || isExpired) {
      final theme = Theme.of(context);
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Tidak Bisa Menyelesaikan'),
              content: Text(
                rule.isCompleted
                    ? 'Aturan ini sudah selesai.'
                    : 'Aturan ini sudah melewati batas waktu.',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final updatedRule = Rule(
      id: rule.id,
      name: rule.name,
      durationMinutes: rule.durationMinutes,
      createdAt: rule.createdAt,
      isCompleted: true,
      isViolated: rule.isViolated,
    );

    await dbHelper.updateRule(updatedRule);
    fetchRules();
    showSnack('Aturan "${rule.name}" ditandai selesai!', color: Colors.green);
  }

  String _formatRemainingTime(Rule rule) {
    final now = DateTime.now();
    final endTime = rule.createdAt.add(Duration(minutes: rule.durationMinutes));
    if (now.isAfter(endTime)) return 'Waktu habis';
    final remaining = endTime.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return hours > 0 ? '$hours jam $minutes menit lagi' : '$minutes menit lagi';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM, HH:mm').format(dateTime);
  }

  Color _getRuleStatusColor(Rule rule) {
    final now = DateTime.now();
    final endTime = rule.createdAt.add(Duration(minutes: rule.durationMinutes));
    if (rule.isCompleted) return Colors.green;
    if (now.isAfter(endTime)) return Colors.red;
    final remaining = endTime.difference(now).inMinutes;
    return remaining < 15
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;
  }

  Widget _buildRuleCard(Rule rule) {
    final theme = Theme.of(context);
    final endTime = rule.createdAt.add(Duration(minutes: rule.durationMinutes));
    final isExpired = DateTime.now().isAfter(endTime);
    final statusColor = _getRuleStatusColor(rule);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rule.isCompleted
                        ? "Selesai ✅"
                        : isExpired
                        ? "Terlambat ❌"
                        : "Aktif ⏳",
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  '${rule.durationMinutes} menit',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(rule.createdAt),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (!rule.isCompleted && !isExpired) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatRemainingTime(rule),
                    style: TextStyle(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!rule.isCompleted)
                  TextButton.icon(
                    onPressed: () => completeRule(rule),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Selesai'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.secondary),
                  onPressed: () => openForm(rule: rule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteRule(rule.id!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.7)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Aturan Baru'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              floating: true,
              title: const Text(
                'Smart Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.hourglass_top),
                    text: 'Aktif (${_activeRules.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.check_circle),
                    text: 'Selesai (${_completedRules.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.error),
                    text: 'Terlambat (${_expiredRules.length})',
                  ),
                ],
              ),
            ),
          ];
        },
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: fetchRules,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _activeRules.isEmpty
                          ? _buildEmptyState(
                            'Tidak ada aturan aktif saat ini.\nTambahkan aturan baru untuk memulai!',
                            Icons.schedule,
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 88),
                            itemCount: _activeRules.length,
                            itemBuilder:
                                (_, i) => _buildRuleCard(_activeRules[i]),
                          ),
                      _completedRules.isEmpty
                          ? _buildEmptyState(
                            'Belum ada aturan yang diselesaikan',
                            Icons.task_alt,
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 88),
                            itemCount: _completedRules.length,
                            itemBuilder:
                                (_, i) => _buildRuleCard(_completedRules[i]),
                          ),
                      _expiredRules.isEmpty
                          ? _buildEmptyState(
                            'Tidak ada aturan yang terlambat.\nTetap disiplin!',
                            Icons.sentiment_very_satisfied,
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 88),
                            itemCount: _expiredRules.length,
                            itemBuilder:
                                (_, i) => _buildRuleCard(_expiredRules[i]),
                          ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: Container(
        height: 80, // Lebih besar dari sebelumnya
        width: 80, // Lebih besar dari sebelumnya
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              Color.fromARGB(
                255,
                (theme.colorScheme.primary.red + 40).clamp(0, 255),
                (theme.colorScheme.primary.green + 20).clamp(0, 255),
                (theme.colorScheme.primary.blue + 70).clamp(0, 255),
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              spreadRadius: 5,
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact(); // Aktifkan haptic feedback
              ScaffoldMessenger.of(context).clearSnackBars();
              openForm();
            },
            customBorder: const CircleBorder(),
            splashColor: Colors.white.withOpacity(0.4),
            highlightColor: Colors.white.withOpacity(0.3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: const Center(
                child: Icon(Icons.add_rounded, size: 40, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 12,
        elevation: 10,
        child: SizedBox(
          height: 60, // Mengurangi tinggi
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tombol Statistik dengan Label
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/stat');
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pie_chart_rounded,
                        size: 26,
                        color:
                            _currentIndex == 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                      ),
                      Text(
                        'Statistik',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              _currentIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              _currentIndex == 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),

              // Spacer tengah untuk FAB
              const Expanded(child: SizedBox()),

              // Tombol Refresh dengan Label
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                    HapticFeedback.lightImpact();
                    fetchRules();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 26,
                        color:
                            _currentIndex == 1
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                      ),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              _currentIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              _currentIndex == 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
