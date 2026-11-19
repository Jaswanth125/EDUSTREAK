import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/challenge_service.dart';

class CreateChallengeScreen extends StatefulWidget {
  final bool showAppBar;
  const CreateChallengeScreen({super.key, this.showAppBar = false});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedClassId;
  String _challengeType = 'daily'; // 'daily' or 'weekly'
  int _xpReward = 50;
  final _xpController = TextEditingController(text: '50');
  bool _isSubmitting = false;
  Map<String, String> _classNamesMap = {};

  final ChallengeService _challengeService = ChallengeService();

  @override
  void initState() {
    super.initState();
    _loadClassNames();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<void> _loadClassNames() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final teacher = userProvider.currentUser;
    
    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) return;

    final Map<String, String> classNamesMap = {};
    for (final classId in teacher.classIds!) {
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
        _selectedClassId ??= teacher.classIds!.first;
      });
    }
  }

  Future<void> _createChallenge() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a challenge title')),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a challenge description')),
      );
      return;
    }

    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_challengeType == 'daily') {
        await _challengeService.createDailyChallenge(
          classId: _selectedClassId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          xpReward: _xpReward,
        );
      } else {
        await _challengeService.createWeeklyChallenge(
          classId: _selectedClassId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          xpReward: _xpReward,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge created successfully! Assigned to all students in ${_classNamesMap[_selectedClassId] ?? _selectedClassId}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _xpController.text = '50';
        _xpReward = 50;
        
        // Optionally navigate back
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final teacher = userProvider.currentUser;

    if (teacher?.classIds == null || teacher!.classIds!.isEmpty) {
      return const Center(child: Text('No classes assigned', style: TextStyle(color: Colors.white54)));
    }

    final bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Challenge Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Challenge Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Daily'),
                            subtitle: const Text('Expires in 24 hours'),
                            value: 'daily',
                            groupValue: _challengeType,
                            onChanged: (value) {
                              setState(() => _challengeType = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Weekly'),
                            subtitle: const Text('Expires in 7 days'),
                            value: 'weekly',
                            groupValue: _challengeType,
                            onChanged: (value) {
                              setState(() => _challengeType = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Class Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Class',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a class',
                      ),
                      items: teacher.classIds!.map((classId) {
                        final className = _classNamesMap[classId] ?? 'Class $classId';
                        return DropdownMenuItem(
                          value: classId,
                          child: Text(className),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedClassId = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Challenge Title *',
                border: OutlineInputBorder(),
                hintText: 'e.g., Daily Reading Challenge',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                hintText: 'Describe what students need to do...',
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 16),
            
            // XP Reward
            TextField(
              controller: _xpController,
              decoration: const InputDecoration(
                labelText: 'XP Reward',
                border: OutlineInputBorder(),
                hintText: '50',
                suffixText: 'XP',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _xpReward = int.tryParse(value) ?? 50;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This challenge will be automatically assigned to all students in the selected class.',
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _createChallenge,
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
                      'Create Challenge',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Challenge'),
        ),
        body: bodyContent,
      );
    }
    return bodyContent;
  }
}

