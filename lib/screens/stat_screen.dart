import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db_helper.dart';
import 'dart:math' as math;

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State createState() => _StatScreenState();
}

class _StatScreenState extends State<StatScreen>
    with SingleTickerProviderStateMixin {
  final dbHelper = DBHelper();
  int completed = 0;
  int violated = 0;
  int ongoing = 0;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    loadStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future loadStats() async {
    setState(() {
      isLoading = true;
    });

    final rules = await dbHelper.getRules();
    final now = DateTime.now();

    int done = 0;
    int fail = 0;
    int active = 0;

    for (var rule in rules) {
      final endTime = rule.createdAt.add(
        Duration(minutes: rule.durationMinutes),
      );
      if (rule.isCompleted) {
        done++;
      } else if (now.isAfter(endTime)) {
        fail++;
      } else {
        active++;
      }
    }

    setState(() {
      completed = done;
      violated = fail;
      ongoing = active;
      isLoading = false;
    });
  }

  Color _getTouchedSectionColor(int touchedIndex) {
    switch (touchedIndex) {
      case 0:
        return Colors.green.shade700;
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  double _calculatePercentage(int value, int total) {
    if (total == 0) return 0;
    return (value / total * 100);
  }

  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = completed + violated + ongoing;
    final completionRate =
        total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Aturan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ringkasan',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          total.toString(),
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'Total Aturan',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '$completionRate%',
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        ),
                                        Text(
                                          'Tingkat Penyelesaian',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Chart Title
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Distribusi Status Aturan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Pie Chart
                      SizedBox(
                        height: 280,
                        child:
                            total == 0
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bar_chart,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Belum ada data untuk ditampilkan',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) {
                                        return PieChart(
                                          PieChartData(
                                            pieTouchData: PieTouchData(
                                              touchCallback: (
                                                FlTouchEvent event,
                                                pieTouchResponse,
                                              ) {
                                                setState(() {
                                                  if (!event
                                                          .isInterestedForInteractions ||
                                                      pieTouchResponse ==
                                                          null ||
                                                      pieTouchResponse
                                                              .touchedSection ==
                                                          null) {
                                                    _touchedIndex = -1;
                                                    return;
                                                  }
                                                  _touchedIndex =
                                                      pieTouchResponse
                                                          .touchedSection!
                                                          .touchedSectionIndex;
                                                });
                                              },
                                            ),
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 40,
                                            sections: [
                                              PieChartSectionData(
                                                color:
                                                    _touchedIndex == 0
                                                        ? Colors.green.shade700
                                                        : Colors.green,
                                                value:
                                                    completed.toDouble() *
                                                    _animation.value,
                                                titlePositionPercentageOffset:
                                                    0.6,
                                                title:
                                                    _touchedIndex == 0
                                                        ? '${_calculatePercentage(completed, total).toStringAsFixed(1)}%'
                                                        : 'Selesai',
                                                radius:
                                                    _touchedIndex == 0
                                                        ? 80
                                                        : 70,
                                                titleStyle: TextStyle(
                                                  fontSize:
                                                      _touchedIndex == 0
                                                          ? 16
                                                          : 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                badgeWidget:
                                                    _touchedIndex == 0
                                                        ? _Badge(
                                                          'Selesai',
                                                          size: 40,
                                                          borderColor:
                                                              Colors.green,
                                                        )
                                                        : null,
                                                badgePositionPercentageOffset:
                                                    .98,
                                              ),
                                              PieChartSectionData(
                                                color:
                                                    _touchedIndex == 1
                                                        ? Colors.red.shade700
                                                        : Colors.red,
                                                value:
                                                    violated.toDouble() *
                                                    _animation.value,
                                                titlePositionPercentageOffset:
                                                    0.6,
                                                title:
                                                    _touchedIndex == 1
                                                        ? '${_calculatePercentage(violated, total).toStringAsFixed(1)}%'
                                                        : 'Terlambat',
                                                radius:
                                                    _touchedIndex == 1
                                                        ? 80
                                                        : 70,
                                                titleStyle: TextStyle(
                                                  fontSize:
                                                      _touchedIndex == 1
                                                          ? 16
                                                          : 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                badgeWidget:
                                                    _touchedIndex == 1
                                                        ? _Badge(
                                                          'Terlambat',
                                                          size: 40,
                                                          borderColor:
                                                              Colors.red,
                                                        )
                                                        : null,
                                                badgePositionPercentageOffset:
                                                    .98,
                                              ),
                                              PieChartSectionData(
                                                color:
                                                    _touchedIndex == 2
                                                        ? Colors.orange.shade700
                                                        : Colors.orange,
                                                value:
                                                    ongoing.toDouble() *
                                                    _animation.value,
                                                titlePositionPercentageOffset:
                                                    0.6,
                                                title:
                                                    _touchedIndex == 2
                                                        ? '${_calculatePercentage(ongoing, total).toStringAsFixed(1)}%'
                                                        : 'Aktif',
                                                radius:
                                                    _touchedIndex == 2
                                                        ? 80
                                                        : 70,
                                                titleStyle: TextStyle(
                                                  fontSize:
                                                      _touchedIndex == 2
                                                          ? 16
                                                          : 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                badgeWidget:
                                                    _touchedIndex == 2
                                                        ? _Badge(
                                                          'Aktif',
                                                          size: 40,
                                                          borderColor:
                                                              Colors.orange,
                                                        )
                                                        : null,
                                                badgePositionPercentageOffset:
                                                    .98,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                      ),

                      const SizedBox(height: 24),

                      // Stats Cards Title
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Detail Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Stat Cards
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Column(
                            children: [
                              _AnimatedStatCard(
                                icon: Icons.check_circle,
                                iconColor: Colors.green,
                                label: 'Selesai',
                                value: completed,
                                percentage: _calculatePercentage(
                                  completed,
                                  total,
                                ),
                                animation: _animation,
                                backgroundColor: Colors.green.withOpacity(0.1),
                              ),
                              const SizedBox(height: 12),
                              _AnimatedStatCard(
                                icon: Icons.error,
                                iconColor: Colors.red,
                                label: 'Terlambat',
                                value: violated,
                                percentage: _calculatePercentage(
                                  violated,
                                  total,
                                ),
                                animation: _animation,
                                backgroundColor: Colors.red.withOpacity(0.1),
                              ),
                              const SizedBox(height: 12),
                              _AnimatedStatCard(
                                icon: Icons.hourglass_bottom,
                                iconColor: Colors.orange,
                                label: 'Aktif',
                                value: ongoing,
                                percentage: _calculatePercentage(
                                  ongoing,
                                  total,
                                ),
                                animation: _animation,
                                backgroundColor: Colors.orange.withOpacity(0.1),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(this.text, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: borderColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int value;
  final double percentage;
  final Animation<double> animation;
  final Color backgroundColor;

  const _AnimatedStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.percentage,
    required this.animation,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$value tugas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: 46,
                  width: 46,
                  child: Stack(
                    children: [
                      ShaderMask(
                        shaderCallback: (rect) {
                          return SweepGradient(
                            startAngle: 0.0,
                            endAngle: 2 * math.pi,
                            stops: [animation.value * percentage / 100, 1.0],
                            center: Alignment.center,
                            colors: [iconColor, Colors.grey.withOpacity(0.2)],
                          ).createShader(rect);
                        },
                        child: Container(
                          height: 46,
                          width: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.scaffoldBackgroundColor,
                          ),
                          child: Center(
                            child: Text(
                              '${(percentage * animation.value).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
