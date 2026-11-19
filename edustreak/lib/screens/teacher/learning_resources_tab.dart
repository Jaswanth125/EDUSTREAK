import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import '../../utils/edustreak_theme.dart';
import '../../utils/class_name_helper.dart';

class LearningResourcesTab extends StatefulWidget {
  final UserModel? user;
  final Stream<List<ResourceModel>>? resourcesStream;

  const LearningResourcesTab({super.key, this.user, this.resourcesStream});

  @override
  State<LearningResourcesTab> createState() => _LearningResourcesTabState();
}

class _LearningResourcesTabState extends State<LearningResourcesTab> {
  final ResourceService _resourceService = ResourceService();
  String _selectedClass = 'All';
  String _selectedSubject = 'All';
  String _selectedType = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final teacherClasses = user?.classIds ?? (user?.classId != null ? [user!.classId!] : <String>[]);
    final teacherSubjects = user?.assignedSubjects ?? <String>[];

    final classOptions = ['All', ...teacherClasses];
    final subjectOptions = ['All', ...(teacherSubjects.isNotEmpty ? teacherSubjects : ['Mathematics', 'Science', 'English'])];
    final typeOptions = ['All', 'PDF', 'DOCX', 'PPTX', 'Image', 'Web Link'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;

              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Resource Library',
                    style: EduStreakTheme.fontHeading1(
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload and manage textbooks, study guides, worksheets & presentations.',
                    style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                  ),
                ],
              );

              final uploadButton = ElevatedButton.icon(
                onPressed: () => _showUploadDialog(context, teacherClasses, teacherSubjects),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Upload Resource', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EduStreakTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 14),
                    uploadButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  uploadButton,
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Filters Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: EduStreakTheme.darkCardDecoration(),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class Filter
                _buildDropdownFilter(
                  label: 'Class',
                  value: _selectedClass,
                  items: classOptions,
                  displayMapper: (c) => c == 'All' ? 'All Classes' : ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A'),
                  onChanged: (val) => setState(() => _selectedClass = val ?? 'All'),
                ),

                // Subject Filter
                _buildDropdownFilter(
                  label: 'Subject',
                  value: _selectedSubject,
                  items: subjectOptions,
                  onChanged: (val) => setState(() => _selectedSubject = val ?? 'All'),
                ),

                // Type Filter
                _buildDropdownFilter(
                  label: 'Format',
                  value: _selectedType,
                  items: typeOptions,
                  onChanged: (val) => setState(() => _selectedType = val ?? 'All'),
                ),

                // Search Bar
                SizedBox(
                  width: 220,
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search title or chapter...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0F1535),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF222B5C)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF222B5C)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Resources Stream
          StreamBuilder<List<ResourceModel>>(
            stream: widget.resourcesStream ?? _resourceService.getResourcesForTeacher(
              schoolId: user?.schoolId ?? '',
              teacherId: user?.id ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EduStreakTheme.primaryViolet),
                  ),
                );
              }

              final allResources = snapshot.data ?? [];

              // Apply UI filters
              final filtered = allResources.where((r) {
                if (_selectedClass != 'All' && r.classId != _selectedClass && r.className != _selectedClass) {
                  return false;
                }
                if (_selectedSubject != 'All' && r.subject.toLowerCase() != _selectedSubject.toLowerCase()) {
                  return false;
                }
                if (_selectedType != 'All' && !r.resourceType.toLowerCase().contains(_selectedType.toLowerCase())) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final titleMatch = r.title.toLowerCase().contains(_searchQuery);
                  final chapterMatch = r.chapter.toLowerCase().contains(_searchQuery);
                  if (!titleMatch && !chapterMatch) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                  decoration: EduStreakTheme.darkCardDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 56, color: EduStreakTheme.darkTextMuted),
                      const SizedBox(height: 14),
                      Text(
                        allResources.isEmpty
                            ? 'No Learning Resources Uploaded Yet'
                            : 'No resources match your filters',
                        style: EduStreakTheme.fontHeading2(color: Colors.white, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upload SCERT textbooks, question banks, or lesson slides for your classes.',
                        style: EduStreakTheme.fontBody(color: EduStreakTheme.darkTextSub),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: filtered.map((res) => _buildResourceCard(context, res)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? displayMapper,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Flexible(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1535),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF222B5C)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: items.contains(value) ? value : items.first,
                  dropdownColor: const Color(0xFF0F1535),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  onChanged: onChanged,
                  items: items.map((item) {
                    final display = displayMapper != null ? displayMapper(item) : item;
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        display,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, ResourceModel res) {
    IconData typeIcon;
    Color iconColor;

    switch (res.resourceType.toLowerCase()) {
      case 'pdf':
        typeIcon = Icons.picture_as_pdf_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'docx':
      case 'doc':
        typeIcon = Icons.description_rounded;
        iconColor = Colors.blueAccent;
        break;
      case 'pptx':
      case 'ppt':
        typeIcon = Icons.slideshow_rounded;
        iconColor = Colors.orangeAccent;
        break;
      case 'image':
        typeIcon = Icons.image_rounded;
        iconColor = Colors.tealAccent;
        break;
      case 'weblink':
        typeIcon = Icons.link_rounded;
        iconColor = EduStreakTheme.neonCyan;
        break;
      default:
        typeIcon = Icons.folder_zip_rounded;
        iconColor = EduStreakTheme.primaryViolet;
    }

    final formattedClass = ClassNameHelper.formatClassNameSync(res.className.isNotEmpty ? res.className : res.classId, fallback: 'Class 8A');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: EduStreakTheme.darkCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(typeIcon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        res.title,
                        style: EduStreakTheme.fontLabel(color: Colors.white, weight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: res.isPublished
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: res.isPublished ? Colors.green.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        res.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color: res.isPublished ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Text('$formattedClass • ${res.subject}', style: EduStreakTheme.fontCaption(color: EduStreakTheme.neonCyan)),
                    Text('Chapter: ${res.chapter}', style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextSub)),
                    if (res.fileSize != null)
                      Text(res.fileSize!, style: EduStreakTheme.fontCaption(color: EduStreakTheme.darkTextMuted)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Actions
          IconButton(
            tooltip: res.isPublished ? 'Unpublish' : 'Publish',
            icon: Icon(
              res.isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: res.isPublished ? Colors.greenAccent : Colors.white38,
              size: 20,
            ),
            onPressed: () => _resourceService.togglePublishStatus(res.id, !res.isPublished),
          ),
          IconButton(
            tooltip: 'Delete Resource',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _confirmDelete(context, res),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ResourceModel res) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1535),
        title: const Text('Delete Resource', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove "${res.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _resourceService.deleteResource(res.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, List<String> classes, List<String> subjects) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final chapterController = TextEditingController(text: 'Chapter 1');
    final topicController = TextEditingController();
    final webUrlController = TextEditingController();

    String selectedClass = classes.isNotEmpty ? classes.first : 'Class 8A';
    String selectedSubject = subjects.isNotEmpty ? subjects.first : 'Mathematics';
    String selectedType = 'pdf';
    bool isPublished = true;
    PlatformFile? pickedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0C1030),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF222B5C)),
            ),
            title: const Text('Upload Learning Resource', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Resource Title *',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'e.g. SCERT Class 8 Biology Lab Guide',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Class & Subject Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            dropdownColor: const Color(0xFF0F1535),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Class', labelStyle: TextStyle(color: Colors.white70)),
                            items: classes.map((c) => DropdownMenuItem(value: c, child: Text(ClassNameHelper.formatClassNameSync(c, fallback: 'Class 8A')))).toList(),
                            onChanged: (v) => setDialogState(() => selectedClass = v ?? selectedClass),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSubject,
                            dropdownColor: const Color(0xFF0F1535),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: Colors.white70)),
                            items: (subjects.isNotEmpty ? subjects : ['Mathematics', 'Science', 'English'])
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => selectedSubject = v ?? selectedSubject),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Chapter & Format Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chapterController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Chapter / Unit',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            dropdownColor: const Color(0xFF0F1535),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(labelText: 'Format', labelStyle: TextStyle(color: Colors.white70)),
                            items: const [
                              DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                              DropdownMenuItem(value: 'docx', child: Text('Word Document (DOCX)')),
                              DropdownMenuItem(value: 'pptx', child: Text('Presentation (PPTX)')),
                              DropdownMenuItem(value: 'image', child: Text('Diagram / Image')),
                              DropdownMenuItem(value: 'weblink', child: Text('Web / Video Link')),
                            ],
                            onChanged: (v) => setDialogState(() => selectedType = v ?? selectedType),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (selectedType == 'weblink')
                      TextField(
                        controller: webUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Web Link URL *',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'https://...',
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1535),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF222B5C)),
                        ),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.any,
                                  withData: true,
                                );
                                if (result != null && result.files.isNotEmpty) {
                                  setDialogState(() {
                                    pickedFile = result.files.first;
                                  });
                                }
                              },
                              icon: const Icon(Icons.attach_file_rounded, size: 16),
                              label: const Text('Choose File'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pickedFile != null ? pickedFile!.name : 'No file chosen',
                                style: TextStyle(
                                  color: pickedFile != null ? Colors.white : Colors.white38,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Description
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Publish Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Publish Immediately to Students', style: TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: const Text('Enrolled students can immediately access and download this material', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      value: isPublished,
                      activeColor: EduStreakTheme.neonCyan,
                      onChanged: (v) => setDialogState(() => isPublished = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a resource title')),
                          );
                          return;
                        }

                        if (selectedType != 'weblink' && pickedFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please choose a file to upload')),
                          );
                          return;
                        }

                        setDialogState(() => isUploading = true);

                        String finalUrl = '';
                        String fileSize = '0 KB';

                        if (selectedType == 'weblink') {
                          final webUrl = webUrlController.text.trim();
                          if (webUrl.isEmpty) {
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid web URL')),
                            );
                            return;
                          }
                          finalUrl = webUrl;
                          fileSize = 'Web Link';
                        } else if (pickedFile != null) {
                          Uint8List? bytes = pickedFile!.bytes;
                          if (bytes == null && !kIsWeb && pickedFile!.path != null) {
                            try {
                              bytes = await io.File(pickedFile!.path!).readAsBytes();
                            } catch (_) {}
                          }

                          if (bytes == null) {
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not read file data. Please try again.')),
                            );
                            return;
                          }

                          fileSize = '${(pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB';
                          try {
                            finalUrl = await _resourceService.uploadResourceFile(
                              fileBytes: bytes,
                              fileName: pickedFile!.name,
                              schoolId: widget.user?.schoolId ?? 'school_default',
                            );
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to upload file to storage: $e')),
                            );
                            return;
                          }
                        }

                        final resource = ResourceModel(
                          id: '',
                          schoolId: widget.user?.schoolId ?? '',
                          classId: selectedClass,
                          className: ClassNameHelper.formatClassNameSync(selectedClass, fallback: 'Class 8A'),
                          subject: selectedSubject,
                          chapter: chapterController.text.trim().isNotEmpty ? chapterController.text.trim() : 'Chapter 1',
                          topic: topicController.text.trim(),
                          title: title,
                          description: descController.text.trim(),
                          resourceType: selectedType,
                          fileUrl: finalUrl,
                          fileSize: fileSize,
                          uploadedBy: widget.user?.id ?? '',
                          uploadedByName: widget.user?.name ?? 'Teacher',
                          createdAt: DateTime.now(),
                          isPublished: isPublished,
                        );

                        await _resourceService.createResource(resource);

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Resource "$title" uploaded successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: EduStreakTheme.primaryViolet),
                child: isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Upload Resource', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
