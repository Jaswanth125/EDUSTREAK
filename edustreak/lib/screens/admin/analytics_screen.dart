import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Future<Map<String, int>>? _engagementDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshEngagementData();
  }

  void _refreshEngagementData() {
    setState(() {
      _engagementDataFuture = _getDailyEngagementData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(context),
            const SizedBox(height: 24),
            _buildTopStreaks(context),
            const SizedBox(height: 24),
            _buildEngagementChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Students',
            Icons.people,
            Colors.blue,
            () => _getTotalUsers('student'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Teachers',
            Icons.person,
            Colors.green,
            () => _getTotalUsers('teacher'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Future<int> Function() future,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<int>(
          future: future(),
          builder: (context, snapshot) {
            final value = snapshot.data ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  value.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopStreaks(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Streaks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No students found'),
                    ),
                  );
                }

                // Sort students by streak in memory
                final students = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'id': doc.id,
                    'name': data['name'] ?? 'Unknown',
                    'streak': data['streak'] ?? 0,
                  };
                }).toList();

                // Sort by streak descending
                students.sort((a, b) => (b['streak'] as int).compareTo(a['streak'] as int));

                // Take top 5
                final topStudents = students.take(5).toList();

                if (topStudents.isEmpty || topStudents.every((s) => (s['streak'] as int) == 0)) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No streak data available'),
                    ),
                  );
                }

                return Column(
                  children: topStudents.asMap().entries.map((entry) {
                    final student = entry.value;
                    final rank = entry.key + 1;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRankColor(rank),
                        child: Text(
                          rank.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(student['name'] as String),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('${student['streak']} days'),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementChart(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Daily Engagement (Last 7 Days)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshEngagementData,
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<Map<String, int>>(
                future: _engagementDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Calculate last 7 days
                  final now = DateTime.now();
                  final last7Days = List.generate(7, (index) {
                    final date = now.subtract(Duration(days: 6 - index));
                    // Format date as YYYY-MM-DD for comparison
                    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    return {
                      'date': date,
                      'dateStr': dateStr,
                      'dayName': _getDayName(date.weekday),
                    };
                  });

                  final attendanceData = snapshot.data ?? <String, int>{};

                  // Get max value for scaling
                  final maxValue = attendanceData.values.isEmpty
                      ? 10.0
                      : (attendanceData.values.isNotEmpty
                          ? attendanceData.values.reduce((a, b) => a > b ? a : b).toDouble()
                          : 0.0);
                  final chartMax = maxValue == 0 ? 10.0 : (maxValue * 1.2).ceilToDouble();

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMax,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blue,
                          tooltipRoundedRadius: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final dayData = last7Days[group.x];
                            final count = attendanceData[dayData['dateStr'] as String] ?? 0;
                            return BarTooltipItem(
                              '${dayData['dayName']}\n$count students',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < last7Days.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    last7Days[index]['dayName'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() % 5 == 0 || value.toInt() == chartMax.toInt()) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                          left: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      barGroups: last7Days.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dayData = entry.value;
                        final count = attendanceData[dayData['dateStr'] as String] ?? 0;
                        
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              color: count > 0 ? Colors.blue : Colors.grey[300]!,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getDailyEngagementData() async {
    try {
      final attendanceData = <String, int>{};
      
      // Calculate last 7 days
      final now = DateTime.now();
      final last7Days = List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });

      // Initialize all dates with 0
      for (final dateStr in last7Days) {
        attendanceData[dateStr] = 0;
      }

      // Get all students
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        return attendanceData;
      }

      // Get all class IDs
      final classIds = <String>{};
      for (final studentDoc in studentsSnapshot.docs) {
        final data = studentDoc.data();
        final classId = data['classId'] as String?;
        if (classId != null && classId.isNotEmpty) {
          classIds.add(classId);
        }
      }

      // Query attendance summaries for current month
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final summaryFutures = classIds.map((classId) async {
        try {
          final summaryId = '${classId}_$currentMonth';
          final summaryDoc = await FirebaseFirestore.instance
              .collection('attendanceSummary')
              .doc(summaryId)
              .get();
          
          if (summaryDoc.exists) {
            final data = summaryDoc.data();
            if (data != null) {
              final presentDays = data['presentDays'] as Map<String, dynamic>? ?? {};
              return presentDays;
            }
          }
        } catch (e) {
          debugPrint('Error fetching attendance summary for class $classId: $e');
        }
        return <String, dynamic>{};
      }).toList();

      final summaries = await Future.wait(summaryFutures);
      
      // Aggregate present days across all classes
      final studentPresentDays = <String, Set<String>>{};
      for (final summary in summaries) {
        summary.forEach((studentId, count) {
          if (count is int && count > 0) {
            studentPresentDays.putIfAbsent(studentId, () => <String>{}).add(studentId);
          }
        });
      }

      // For each date, count how many students were present
      // We'll use individual attendance records for the last 7 days as a fallback
      // since summaries are monthly aggregates
      for (final dateStr in last7Days) {
        int presentCount = 0;
        
        // Query attendance records for this specific date
        final batchFutures = studentsSnapshot.docs.map((studentDoc) async {
          try {
            final attendanceDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(studentDoc.id)
                .collection('attendanceRecords')
                .doc(dateStr)
                .get();
            
            if (attendanceDoc.exists) {
              final data = attendanceDoc.data();
              if (data != null && data['present'] == true) {
                return 1;
              }
            }
          } catch (e) {
            // Silently skip errors
          }
          return 0;
        }).toList();
        
        final results = await Future.wait(batchFutures);
        presentCount = results.fold(0, (sum, count) => sum + count);
        
        attendanceData[dateStr] = presentCount;
      }

      debugPrint('Daily engagement data: $attendanceData');
      return attendanceData;
    } catch (e) {
      debugPrint('Error getting daily engagement data: $e');
      return <String, int>{};
    }
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  Future<int> _getTotalUsers(String role) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs.length;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }
}

