import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../utils/theme.dart';
import 'task_detail_screen.dart';
import 'ai_practice_tab.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser?.classId == null) {
      return const Scaffold(
        body: Center(
          child: Text('No class assigned'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.primaryGlowShadow,
            ),
          ),
          foregroundColor: Colors.white,
          title: const Text('My Tasks'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: 'Assigned'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI Practice'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<List<TaskModel>>(
        stream: TaskService().getTasksForStudent(currentUser!.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks assigned',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isCompleted = task.submissions[currentUser.id] == 'completed' ||
                  task.submissions[currentUser.id] == 'submitted';
              final isOverdue = DateTime.now().isAfter(task.dueDate) && !isCompleted;
              final hasGrade = task.marks[currentUser.id] != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                          colors: [Colors.green[50]!, Colors.green[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : isOverdue
                          ? LinearGradient(
                              colors: [Colors.red[50]!, Colors.red[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.pink[50]!, Colors.purple[50]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.3)
                          : isOverdue
                              ? Colors.red.withOpacity(0.3)
                              : Colors.purple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(taskId: task.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green
                                  : isOverdue
                                      ? Colors.red
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCompleted
                                          ? Colors.green
                                          : isOverdue
                                              ? Colors.red
                                              : Colors.blue)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isCompleted ? Icons.check_circle : Icons.assignment,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject/Topic
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.green[900]
                                        : isOverdue
                                            ? Colors.red[900]
                                            : Colors.purple[900],
                                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                // Due Date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: isOverdue ? Colors.red : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOverdue ? Colors.red : Colors.grey[600],
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // XP Reward
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reward: ${task.xpReward} XP',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Grade
                                if (hasGrade) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.grade, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Grade: ${task.marks[currentUser.id]} / ${task.maxMarks}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                // Status
                                if (task.submissions[currentUser.id] == 'submitted') ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Submitted (Awaiting grading)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Arrow Icon
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 20,
                            color: isCompleted
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      AiPracticeTab(
        studentId: currentUser.id,
        classId: currentUser.classId!,
      ),
    ],
  ),
),
    );
  }
}

