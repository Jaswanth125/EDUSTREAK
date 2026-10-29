import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No classes found'));
          }

          final allClasses = snapshot.data!.docs;
          final teacherClassIds = teacher.classIds ?? [];
          final assignedClasses = allClasses.where((doc) {
            return teacherClassIds.contains(doc.id);
          }).toList();
          final unassignedClasses = allClasses.where((doc) {
            return !teacherClassIds.contains(doc.id);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.class_,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'My Classes',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${assignedClasses.length} class${assignedClasses.length != 1 ? 'es' : ''} assigned',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Assigned Classes
                if (assignedClasses.isNotEmpty) ...[
                  Text(
                    'My Classes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...assignedClasses.map((classDoc) {
                    final classData = classDoc.data() as Map<String, dynamic>;
                    return _buildClassCard(
                      context,
                      classDoc.id,
                      classData['name'] ?? classDoc.id,
                      true,
                      () => _removeClass(context, teacher.id, classDoc.id, userProvider),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],

                // Available Classes
                if (unassignedClasses.isNotEmpty) ...[
                  Text(
                    'Available Classes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...unassignedClasses.map((classDoc) {
                    final classData = classDoc.data() as Map<String, dynamic>;
                    return _buildClassCard(
                      context,
                      classDoc.id,
                      classData['name'] ?? classDoc.id,
                      false,
                      () => _addClass(context, teacher.id, classDoc.id, userProvider),
                    );
                  }).toList(),
                ],

                if (assignedClasses.isEmpty && unassignedClasses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.class_,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No classes available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    String classId,
    String className,
    bool isAssigned,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isAssigned ? AppTheme.successGradient : null,
        color: isAssigned ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAssigned
            ? null
            : Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isAssigned
                    ? AppTheme.successColor
                    : Colors.grey[300]!)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAssigned
                        ? Colors.white.withOpacity(0.3)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: isAssigned ? Colors.white : AppTheme.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAssigned ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Class ID: $classId',
                        style: TextStyle(
                          fontSize: 14,
                          color: isAssigned
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isAssigned
                        ? Colors.white.withOpacity(0.3)
                        : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAssigned ? Icons.check_circle : Icons.add_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAssigned ? 'Remove' : 'Add',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addClass(
    BuildContext context,
    String teacherId,
    String classId,
    UserProvider userProvider,
  ) async {
    try {
      final teacherRef =
          FirebaseFirestore.instance.collection('users').doc(teacherId);
      final teacherDoc = await teacherRef.get();
      final currentClassIds =
          List<String>.from(teacherDoc.data()?['classIds'] ?? []);

      if (currentClassIds.contains(classId)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Already assigned to this class')),
          );
        }
        return;
      }

      currentClassIds.add(classId);
      await teacherRef.update({'classIds': currentClassIds});

      // Refresh user provider
      await userProvider.loadUser(teacherId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _removeClass(
    BuildContext context,
    String teacherId,
    String classId,
    UserProvider userProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Class'),
        content: const Text(
            'Are you sure you want to remove yourself from this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final teacherRef =
          FirebaseFirestore.instance.collection('users').doc(teacherId);
      final teacherDoc = await teacherRef.get();
      final currentClassIds =
          List<String>.from(teacherDoc.data()?['classIds'] ?? []);

      currentClassIds.remove(classId);
      await teacherRef.update({'classIds': currentClassIds});

      // Refresh user provider
      await userProvider.loadUser(teacherId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Class removed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

