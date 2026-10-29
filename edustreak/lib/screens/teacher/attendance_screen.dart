import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/attendance_service.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, String> _classNamesMap = {};
  Map<String, bool> _studentAttendance = {}; // studentId -> present (true/false)
  bool _isMarked = false;
  bool _isLoadingAttendance = false;
  bool _isSubmitting = false;
  Map<String, AttendanceRecord>? _existingAttendance;

  @override
  void initState() {
    super.initState();
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;
    
    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) return;

    final Map<String, String> classNamesMap = {};
    var unnamedCounter = 1;
    for (final classId in teacher.classIds!) {
      try {
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .get();
        if (classDoc.exists) {
          final data = classDoc.data();
          final rawName = (data?['name'] as String?)?.trim() ?? '';
          classNamesMap[classId] =
              rawName.isNotEmpty ? rawName : 'Class ${unnamedCounter++}';
        } else {
          classNamesMap[classId] = 'Class ${unnamedCounter++}';
        }
      } catch (e) {
        classNamesMap[classId] = 'Class ${unnamedCounter++}';
      }
    }
    
    if (mounted) {
      setState(() {
        _classNamesMap = classNamesMap;
      });
      _loadAttendanceForDate();
    }
  }

  Future<void> _loadAttendanceForDate() async {
    if (_selectedClassId == null) return;

    setState(() {
      _isMarked = false;
      _studentAttendance = {};
      _existingAttendance = null;
      _isLoadingAttendance = true;
    });

    try {
      final dateKey = AttendanceService.getDateKey(_selectedDate);
      
      // Check if already marked
      final isMarked = await _attendanceService.isAttendanceMarked(
        _selectedClassId!,
        dateKey,
      );

      if (isMarked) {
        if (mounted) {
          setState(() {
            _isMarked = true;
            _existingAttendance = const {};
            _studentAttendance = {};
            _isLoadingAttendance = false;
          });
        }
        // Load existing attendance
        final existing = await _attendanceService.getClassAttendanceForDate(
          _selectedClassId!,
          dateKey,
        );
        if (mounted) {
          setState(() {
            _existingAttendance = existing;
            // Convert existing records to studentAttendance map
            for (final entry in existing.entries) {
              _studentAttendance[entry.key] = entry.value.present;
            }
          });
        }
      } else {
        await _loadStudents();
        if (mounted) {
          setState(() {
            _isLoadingAttendance = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
        setState(() {
          _isLoadingAttendance = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) return;

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: _selectedClassId)
          .get();

      final Map<String, bool> attendance = {};
      for (final doc in studentsSnapshot.docs) {
        // Preserve existing attendance state if available, otherwise default to present
        attendance[doc.id] = _studentAttendance[doc.id] ?? true;
      }

      if (mounted) {
        setState(() {
          _studentAttendance = attendance;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }


  Future<void> _submitAttendance({List<UserModel>? studentsList}) async {
    if (_selectedClassId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a class')),
        );
      }
      return;
    }

    // If students list is provided, ensure all students are in the attendance map
    if (studentsList != null && studentsList.isNotEmpty) {
      bool updated = false;
      for (final student in studentsList) {
        if (!_studentAttendance.containsKey(student.id)) {
          _studentAttendance[student.id] = true; // Default to present
          updated = true;
        }
      }
      if (updated && mounted) {
        setState(() {});
        // Wait a moment for state to update
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (_studentAttendance.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No students found. Please try again.')),
        );
      }
      return;
    }

    if (_isMarked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance already marked for this date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher information not found')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dateKey = AttendanceService.getDateKey(_selectedDate);
      
      await _attendanceService.markClassAttendance(
        classId: _selectedClassId!,
        dateKey: dateKey,
        studentAttendance: _studentAttendance,
        markedBy: teacher.id,
      );

      if (mounted) {
        setState(() {
          _isMarked = true;
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload to show locked state
        await _loadAttendanceForDate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No classes assigned')),
      );
    }

    _selectedClassId ??= teacher.classIds!.first;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Mark Attendance'),
        actions: [
          if (_isMarked)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.lock, color: Colors.orange),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          // Date and Class Selector
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor
                      .withAlpha((0.15 * 255).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingAttendance)
                  const LinearProgressIndicator(
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                if (_isLoadingAttendance) const SizedBox(height: 8),
                Text(
                  'Select Class & Date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClassId,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          label: Container(),
                          helperText: '',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor
                                  .withAlpha((0.4 * 255).round()),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: AppTheme.primaryColor
                                  .withAlpha((0.4 * 255).round()),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.deepPurpleAccent.shade100,
                              width: 1.8,
                            ),
                          ),
                        ),
                        items: teacher.classIds!.map((classId) {
                          final className = _classNamesMap[classId] ?? 'Class';
                          return DropdownMenuItem(
                            value: classId,
                            child: Text(className),
                          );
                        }).toList(),
                        onChanged: _isMarked
                            ? null
                            : (value) {
                                setState(() => _selectedClassId = value);
                                _loadAttendanceForDate();
                              },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 170),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _isMarked
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 30)),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null) {
                                      setState(() => _selectedDate = date);
                                      _loadAttendanceForDate();
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            label: Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isMarked)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Attendance already submitted for ${_formatDate(_selectedDate)}',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _loadAttendanceForDate(),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!_isMarked && _studentAttendance.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _studentAttendance.updateAll((key, value) => true);
                              });
                            },
                            icon: const Icon(Icons.done_all),
                            label: const Text('Mark All Present'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _studentAttendance.updateAll((key, value) => false);
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Mark All Absent'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'student')
                  .where('classId', isEqualTo: _selectedClassId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students in this class'));
                }

                final students = snapshot.data!.docs.map((doc) {
                  return UserModel.fromMap(
                    doc.data() as Map<String, dynamic>..['id'] = doc.id,
                  );
                }).toList();

                // Initialize student attendance map when students are loaded (without setState during build)
                if (students.isNotEmpty && !_isMarked) {
                  bool needsInit = false;
                  
                  // Check if initialization is needed
                  for (final student in students) {
                    if (!_studentAttendance.containsKey(student.id)) {
                      _studentAttendance[student.id] = true; // Initialize immediately
                      needsInit = true;
                    }
                  }
                  
                  // Schedule state update after build completes if needed
                  if (needsInit) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_isMarked) {
                        setState(() {});
                      }
                    });
                  }
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentAttendanceCard(student);
                        },
                      ),
                    ),
                    
                    // Submit Button - Always show when students exist and not marked
                    if (!_isMarked && students.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withAlpha((0.1 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () => _submitAttendance(studentsList: students),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Submit Attendance',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStudentAttendanceCard(UserModel student) {
    final isPresent = _studentAttendance[student.id] ?? true;
    final existingRecord = _existingAttendance?[student.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(student.name[0].toUpperCase()),
        ),
        title: Text(student.name),
        subtitle: existingRecord != null
            ? Text(
                existingRecord.present ? 'Present' : 'Absent',
                style: TextStyle(
                  color: existingRecord.present ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text('Streak: ${student.streak} days • ${student.xp} XP'),
        trailing: _isMarked
            ? Icon(
                existingRecord?.present == true ? Icons.check_circle : Icons.cancel,
                color: existingRecord?.present == true ? Colors.green : Colors.red,
                size: 32,
              )
            : Switch(
                value: isPresent,
                onChanged: (value) {
                  setState(() {
                    _studentAttendance[student.id] = value;
                  });
                },
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.green;
                  }
                  return null;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.green.withAlpha((0.4 * 255).round());
                  }
                  return null;
                }),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
