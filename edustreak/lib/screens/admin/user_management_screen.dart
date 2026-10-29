import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('User Management'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddUserDialog(context),
              tooltip: 'Add User',
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs.map((doc) {
            return UserModel.fromMap(
              doc.data() as Map<String, dynamic>..['id'] = doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRoleColor(user.role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getRoleColor(user.role),
                                ),
                              ),
                            ),
                            if (user.role == 'student') ...[
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 14,
                                    color: AppTheme.streakColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.streak}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.streakColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppTheme.accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.xp}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[700],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteUser(context, user.id);
                      } else if (value == 'edit') {
                        _editUser(context, user);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String? _selectedRole = 'student';
    String? _selectedClassId;
    String? _selectedParentId;
    bool _isLoading = false;

    // Get available classes
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .get();
    final classes = classesSnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc.data()['name'] ?? doc.id};
    }).toList();

    // Get available students for parent role
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    final students = studentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'name': data['name'] ?? 'Unknown'};
    }).toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        _selectedClassId = null;
                        _selectedParentId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedRole == 'student') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: classes.map((classData) {
                        return DropdownMenuItem<String>(
                          value: classData['id'] as String?,
                          child: Text(classData['name'] ?? classData['id']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedRole == 'student' && (value == null || value.isEmpty)) {
                          return 'Please select a class';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_selectedRole == 'teacher') ...[
                    const Text(
                      'Note: Classes can be assigned after user is created',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (_selectedRole == 'parent') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'Child (Student)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.child_care),
                      ),
                      items: students.map((student) {
                        return DropdownMenuItem<String>(
                          value: student['id'] as String?,
                          child: Text(student['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedParentId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedRole == 'parent' && (value == null || value.isEmpty)) {
                          return 'Please select a child';
                        }
                        return null;
                      },
                    ),
                  ],
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(dialogContext).pop();
                _nameController.dispose();
                _emailController.dispose();
                _passwordController.dispose();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  if (!dialogContext.mounted) return;
                  
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final authService = AuthService();
                    final userModel = await authService.signUpWithEmail(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                      name: _nameController.text.trim(),
                      role: _selectedRole!,
                      classId: _selectedClassId,
                      childId: _selectedParentId,
                      allowAdminTeacher: true, // Allow admin/teacher creation from admin dashboard
                    );

                    if (!dialogContext.mounted) return;
                    
                    if (userModel != null) {
                      // Save name before disposing
                      final userName = _nameController.text;
                      
                      // Close dialog first
                      Navigator.of(dialogContext).pop();
                      
                      // Dispose controllers
                      _nameController.dispose();
                      _emailController.dispose();
                      _passwordController.dispose();
                      
                      // Show success message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('User $userName created successfully!'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      throw Exception('Failed to create user');
                    }
                  } catch (e) {
                    // Only update state if dialog context is still mounted
                    if (!dialogContext.mounted) {
                      _nameController.dispose();
                      _emailController.dispose();
                      _passwordController.dispose();
                      return;
                    }
                    
                    setState(() {
                      _isLoading = false;
                    });
                    
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error creating user: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _editUser(BuildContext context, UserModel user) async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: user.name);
    final _emailController = TextEditingController(text: user.email);
    String? _selectedRole = user.role;
    String? _selectedClassId = user.classId;
    String? _selectedParentId = user.childId;
    bool _isLoading = false;

    // Get available classes
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .get();
    final classes = classesSnapshot.docs.map((doc) {
      return {'id': doc.id, 'name': doc.data()['name'] ?? doc.id};
    }).toList();

    // If user's classId is not in the list, try to fetch it or reset to null
    if (_selectedClassId != null && 
        !classes.any((c) => c['id'] == _selectedClassId)) {
      // Try to get the class name from Firestore
      try {
        final classDoc = await FirebaseFirestore.instance
            .collection('classes')
            .doc(_selectedClassId)
            .get();
        if (classDoc.exists) {
          classes.add({
            'id': _selectedClassId!,
            'name': classDoc.data()?['name'] ?? _selectedClassId!,
          });
        } else {
          // Class doesn't exist, reset to null
          _selectedClassId = null;
        }
      } catch (e) {
        // If error, reset to null
        _selectedClassId = null;
      }
    }

    // Get available students for parent role
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    final students = studentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'name': data['name'] ?? 'Unknown'};
    }).toList();

    // If user's childId is not in the list, try to fetch it or reset to null
    if (_selectedParentId != null && 
        !students.any((s) => s['id'] == _selectedParentId)) {
      // Try to get the student name from Firestore
      try {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedParentId)
            .get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data();
          students.add({
            'id': _selectedParentId!,
            'name': studentData?['name'] ?? 'Unknown',
          });
        } else {
          // Student doesn't exist, reset to null
          _selectedParentId = null;
        }
      } catch (e) {
        // If error, reset to null
        _selectedParentId = null;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // Don't allow email change for security
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Email cannot be changed',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'student', child: Text('Student')),
                      DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        if (value != 'student') {
                          _selectedClassId = null;
                        }
                        if (value != 'parent') {
                          _selectedParentId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedRole == 'student') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.class_),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Class'),
                        ),
                        ...classes.map((classData) {
                          final classId = classData['id'] as String?;
                          return DropdownMenuItem<String>(
                            value: classId,
                            child: Text(classData['name'] ?? classId ?? 'Unknown'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value;
                        });
                      },
                    ),
                  ],
                  if (_selectedRole == 'teacher') ...[
                    const Text(
                      'Note: Classes can be managed separately',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                  if (_selectedRole == 'parent') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedParentId,
                      decoration: const InputDecoration(
                        labelText: 'Child (Student)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.child_care),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Child'),
                        ),
                        ...students.map((student) {
                          final studentId = student['id'] as String?;
                          return DropdownMenuItem<String>(
                            value: studentId,
                            child: Text(student['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedParentId = value;
                        });
                      },
                    ),
                  ],
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(dialogContext).pop();
                _nameController.dispose();
                _emailController.dispose();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  if (!dialogContext.mounted) return;
                  
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // Update user data in Firestore
                    final updateData = <String, dynamic>{
                      'name': _nameController.text.trim(),
                      'role': _selectedRole!,
                    };

                    // Handle classId for students
                    if (_selectedRole == 'student') {
                      if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
                        updateData['classId'] = _selectedClassId;
                      } else {
                        // Remove classId if no class selected
                        updateData['classId'] = FieldValue.delete();
                      }
                    } else {
                      // Remove classId if not a student
                      updateData['classId'] = FieldValue.delete();
                    }

                    // Handle childId for parents
                    if (_selectedRole == 'parent') {
                      if (_selectedParentId != null && _selectedParentId!.isNotEmpty) {
                        updateData['childId'] = _selectedParentId;
                      } else {
                        // Remove childId if no child selected
                        updateData['childId'] = FieldValue.delete();
                      }
                    } else {
                      // Remove childId if not a parent
                      updateData['childId'] = FieldValue.delete();
                    }

                    // Update Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update(updateData);

                    // Only proceed if dialog context is still mounted
                    if (!dialogContext.mounted) {
                      _nameController.dispose();
                      _emailController.dispose();
                      return;
                    }
                    
                    // Close dialog first
                    Navigator.of(dialogContext).pop();
                    
                    // Dispose controllers
                    _nameController.dispose();
                    _emailController.dispose();
                    
                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('User updated successfully!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    // Only update state if dialog context is still mounted
                    if (!dialogContext.mounted) {
                      _nameController.dispose();
                      _emailController.dispose();
                      return;
                    }
                    
                    setState(() {
                      _isLoading = false;
                    });
                    
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Error updating user: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Update User'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return AppTheme.primaryColor;
      case 'teacher':
        return AppTheme.successColor;
      case 'parent':
        return AppTheme.accentColor;
      case 'admin':
        return AppTheme.secondaryColor;
      default:
        return Colors.grey;
    }
  }
}

