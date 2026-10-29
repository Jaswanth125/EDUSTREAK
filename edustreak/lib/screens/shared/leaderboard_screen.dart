import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/tier_system.dart';
import '../../widgets/tiered_profile_picture.dart';
import '../../widgets/app_logo.dart';
import 'skill_matrix_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final String? classId; // Optional: for teachers to view specific class
  final String? className; // Optional: class name to display
  final bool showAppBar;

  const LeaderboardScreen({
    super.key,
    this.classId,
    this.className,
    this.showAppBar = true,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _sortBy = 'xp'; // 'xp', 'streak', 'level'
  String? _selectedClassId;
  Map<String, String> _classNamesMap = {};

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    if (user == null) return;

    // For teachers, load all their classes
    if (user.role == 'teacher' && user.classIds != null) {
      final Map<String, String> classNamesMap = {};
      for (final classId in user.classIds!) {
        try {
          final classDoc = await FirebaseFirestore.instance
              .collection('classes')
              .doc(classId)
              .get();
          if (classDoc.exists) {
            final data = classDoc.data();
            String className = data?['name'] ?? '';
            if (className.isEmpty) {
              final match = RegExp(r'(\d+)').firstMatch(classId);
              if (match != null) {
                className = 'Class ${match.group(1)}';
              } else {
                className = 'Class ${classId.substring(0, classId.length > 8 ? 8 : classId.length)}...';
              }
            }
            classNamesMap[classId] = className;
          } else {
            final match = RegExp(r'(\d+)').firstMatch(classId);
            final className = match != null ? 'Class ${match.group(1)}' : 'Class $classId';
            classNamesMap[classId] = className;
          }
        } catch (e) {
          classNamesMap[classId] = 'Class $classId';
        }
      }
      
      if (mounted) {
        setState(() {
          _classNamesMap = classNamesMap;
          if (_selectedClassId == null && user.classIds!.isNotEmpty) {
            _selectedClassId = user.classIds!.first;
          }
        });
      }
    } else if (user.role == 'parent' && user.childId != null) {
      // For parents, get child's class
      try {
        final childDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.childId)
            .get();
        if (childDoc.exists) {
          final childData = childDoc.data();
          final childClassId = childData?['classId'];
          if (childClassId != null) {
            final classDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(childClassId)
                .get();
            if (classDoc.exists) {
              final data = classDoc.data();
              String className = data?['name'] ?? '';
              if (className.isEmpty) {
                final match = RegExp(r'(\d+)').firstMatch(childClassId);
                if (match != null) {
                  className = 'Class ${match.group(1)}';
                } else {
                  className = 'Class ${childClassId.substring(0, childClassId.length > 8 ? 8 : childClassId.length)}...';
                }
              }
              setState(() {
                _selectedClassId = childClassId;
                _classNamesMap[childClassId] = className;
              });
            }
          }
        }
      } catch (e) {
        // Handle error
      }
    }
  }

  Stream<List<UserModel>> _getStudentsStream(String? classId) {
    if (classId == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
      final students = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
      
      // Sort in memory to avoid composite index
      switch (_sortBy) {
        case 'streak':
          students.sort((a, b) => b.streak.compareTo(a.streak));
          break;
        case 'level':
          students.sort((a, b) => b.level.compareTo(a.level));
          break;
        case 'xp':
        default:
          students.sort((a, b) => b.xp.compareTo(a.xp));
          break;
      }
      
      return students;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // For students, use their classId directly
    // For teachers, use selected class or first class
    // For parents, use child's class
    final displayClassId = widget.classId ?? 
                          (currentUser.role == 'student' ? currentUser.classId : 
                           currentUser.role == 'teacher' ? _selectedClassId :
                           currentUser.role == 'parent' ? _selectedClassId : null);

    // Show waiting if teacher has classes but none selected yet
    if (currentUser.role == 'teacher' && 
        currentUser.classIds != null && 
        currentUser.classIds!.isNotEmpty && 
        _selectedClassId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (displayClassId == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        appBar: widget.showAppBar ? _buildAppBar('Leaderboard') : null,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: AppTheme.textTertiary),
                const SizedBox(height: 16),
                Text(
                  currentUser.role == 'teacher'
                      ? 'No classes assigned'
                      : 'No class assigned',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String classId = displayClassId;
    final displayClassName =
        widget.className ?? _classNamesMap[classId] ?? 'Leaderboard';

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: widget.showAppBar ? _buildAppBar(displayClassName) : null,
      body: Column(
        children: [
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayClassName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildSortMenu(iconColor: AppTheme.primaryColor),
                ],
              ),
            ),
          // Class selector for teachers
          if (currentUser.role == 'teacher' && _classNamesMap.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.darkSurface,
              child: DropdownButtonFormField<String>(
                value: _selectedClassId,
                dropdownColor: AppTheme.darkSurfaceVariant,
                decoration: InputDecoration(
                  labelText: 'Select Class',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.darkSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.darkBorder),
                  ),
                ),
                style: TextStyle(color: AppTheme.textPrimary),
                items: _classNamesMap.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, style: TextStyle(color: AppTheme.textPrimary)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClassId = value;
                  });
                },
              ),
            ),
          ],
          // Sort indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.darkSurface,
            child: Row(
              children: [
                Icon(
                  _sortBy == 'xp'
                      ? Icons.star
                      : _sortBy == 'streak'
                          ? Icons.local_fire_department
                          : Icons.trending_up,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sorted by: ${_sortBy.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Leaderboard list
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _getStudentsStream(displayClassId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.leaderboard, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No students found',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final rank = index + 1;
                    final isCurrentUser = student.id == currentUser.id && currentUser.role == 'student';

                    return _buildLeaderboardCard(
                      context,
                      student,
                      rank,
                      isCurrentUser,
                      _sortBy,
                      currentUser.role == 'teacher', // Make clickable for teachers
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: AppLogo(size: 30),
      ),
      leadingWidth: 66,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: AppTheme.primaryGlowShadow,
        ),
      ),
      foregroundColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        _buildSortMenu(),
      ],
    );
  }

  Widget _buildSortMenu({Color? iconColor}) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: iconColor),
      color: AppTheme.darkSurfaceVariant,
      onSelected: (value) {
        setState(() {
          _sortBy = value;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'xp',
          child: Row(
            children: [
              Icon(Icons.star, size: 20, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text('Sort by XP', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'streak',
          child: Row(
            children: [
              Icon(Icons.local_fire_department, size: 20, color: AppTheme.streakColor),
              const SizedBox(width: 8),
              Text('Sort by Streak', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'level',
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text('Sort by Level', style: TextStyle(color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    UserModel student,
    int rank,
    bool isCurrentUser,
    String sortBy,
    bool isClickable,
  ) {
    final rankColor = _getRankColor(rank);
    final isTopThree = rank <= 3;
    final tier = TierSystem.getTier(student.xp);

    Widget cardContent = Container(
      margin: EdgeInsets.only(
        bottom: 16,
        left: isTopThree ? 4 : 0,
        right: isTopThree ? 4 : 0,
      ),
      decoration: BoxDecoration(
        gradient: isTopThree
            ? LinearGradient(
                colors: [
                  rankColor.withOpacity(0.15),
                  rankColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.darkCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTopThree
              ? rankColor.withAlpha((0.6 * 255).round())
              : AppTheme.darkBorder.withAlpha((0.3 * 255).round()),
          width: isTopThree ? 2.5 : 1.5,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withAlpha((0.4 * 255).round()),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ]
            : AppTheme.cardGlowShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Rank badge with profile picture
            Stack(
              children: [
                // Profile picture with tier border
                TieredProfilePicture(
                  user: student,
                  size: 50,
                  showTierBorder: true,
                ),
                // Rank badge overlay
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.darkBackground, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: rankColor.withAlpha((0.5 * 255).round()),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Student info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.name,
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Tier badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: TierSystem.getTierGradient(tier),
                          borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: tier.color.withAlpha((0.5 * 255).round()),
                              width: 1,
                            ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tier.icon,
                              style: const TextStyle(fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tier.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Stats row
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 12, color: AppTheme.streakColor),
                          const SizedBox(width: 2),
                          Text(
                            '${student.streak}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: AppTheme.accentColor),
                          const SizedBox(width: 2),
                          Text(
                            '${student.xp}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, size: 12, color: AppTheme.primaryColor),
                          const SizedBox(width: 2),
                          Text(
                            'Lv.${student.level}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Score display
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  sortBy == 'xp'
                      ? '${student.xp}'
                      : sortBy == 'streak'
                          ? '${student.streak}'
                          : '${student.level}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
                Text(
                  sortBy == 'xp' ? 'XP' : sortBy == 'streak' ? 'Days' : 'Level',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isClickable) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SkillMatrixScreen(
                studentId: student.id,
                studentName: student.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.blue;
    }
  }
}

