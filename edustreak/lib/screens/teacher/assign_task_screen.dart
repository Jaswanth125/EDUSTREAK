import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'create_challenge_screen.dart';

class AssignTaskScreen extends StatefulWidget {
  const AssignTaskScreen({super.key});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  String? _selectedClassId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final List<String> _selectedStudents = [];
  int _xpReward = 50;
  int _maxMarks = 100;
  String _selectedSubject = 'Mathematics';
  final _maxMarksController = TextEditingController(text: '100');
  final Map<String, String> _classNamesMap = {};

  static const List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'Social Studies',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'General Studies',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClassNames();
    });
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
        title: const Text('Assign Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Create Challenge',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateChallengeScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Assign Task',
            onPressed: _showAssignTaskDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedBy', isEqualTo: teacher.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No tasks assigned yet'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAssignTaskDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Assign New Task'),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return TaskModel.fromMap(
              doc.data() as Map<String, dynamic>..['id'] = doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue),
                  title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      const SizedBox(height: 4),
                      Text('Due: ${_formatDate(task.dueDate)}'),
                      Text('Assigned to: ${task.assignedTo.length} students'),
                      Text('Reward: ${task.xpReward} XP', style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTask(task.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;

    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) return;

    final pendingClassIds = teacher.classIds!
        .where((id) => !_classNamesMap.containsKey(id))
        .toList();

    if (pendingClassIds.isEmpty) return;

    try {
      const batchSize = 10;
      for (var i = 0; i < pendingClassIds.length; i += batchSize) {
        final chunk = pendingClassIds.sublist(
          i,
          i + batchSize > pendingClassIds.length
              ? pendingClassIds.length
              : i + batchSize,
        );

        final snapshot = await FirebaseFirestore.instance
            .collection('classes')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final rawName = (data['name'] as String?)?.trim() ?? '';
          _classNamesMap[doc.id] =
              rawName.isNotEmpty ? rawName : 'Class ${doc.id}';
        }

        for (final id in chunk) {
          _classNamesMap.putIfAbsent(id, () => 'Class $id');
        }
      }
    } catch (e) {
      for (final id in pendingClassIds) {
        _classNamesMap[id] = 'Class $id';
      }
    } finally {}
  }

  Future<void> _showAssignTaskDialog() async {
    await _loadClassNames();
    if (!mounted) return;

    _titleController.clear();
    _descriptionController.clear();
    _selectedStudents.clear();
    _dueDate = DateTime.now().add(const Duration(days: 7));
    _xpReward = 50;
    _maxMarks = 100;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;
    if (teacher == null) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign New Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Task Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedClassId,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: teacher.classIds!.map((classId) {
                    final className =
                        _classNamesMap[classId] ?? 'Class $classId';
                    return DropdownMenuItem(
                      value: classId,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedClassId = value);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date: ${_formatDate(_dueDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.book_outlined),
                  ),
                  items: _subjects.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubject = value ?? 'Mathematics');
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(labelText: 'XP Reward'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _xpReward = int.tryParse(value) ?? 50;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maxMarksController,
                  decoration: const InputDecoration(labelText: 'Max Marks'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _maxMarks = int.tryParse(value) ?? 100;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_titleController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty &&
                    _selectedClassId != null) {
                  await _assignTask();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignTask() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;

    if (teacher == null || _selectedClassId == null) return;

    try {
      // Get all students in the class
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: _selectedClassId)
          .get();

      final studentIds = _selectedStudents.isNotEmpty
          ? _selectedStudents
          : studentsSnapshot.docs.map((doc) => doc.id).toList();

      if (studentIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No students in this class')),
          );
        }
        return;
      }

      await TaskService().createTask(
        classId: _selectedClassId!,
        title: _titleController.text,
        description: _descriptionController.text,
        subject: _selectedSubject,
        assignedBy: teacher.id,
        assignedByName: teacher.name,
        dueDate: _dueDate,
        assignedTo: studentIds,
        maxMarks: _maxMarks,
        xpReward: _xpReward,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

