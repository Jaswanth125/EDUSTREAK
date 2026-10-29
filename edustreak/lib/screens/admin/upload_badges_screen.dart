import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../utils/upload_badges.dart';
import '../../utils/theme.dart';

/// Admin screen to upload badges to Firestore
class UploadBadgesScreen extends StatefulWidget {
  const UploadBadgesScreen({super.key});

  @override
  State<UploadBadgesScreen> createState() => _UploadBadgesScreenState();
}

class _UploadBadgesScreenState extends State<UploadBadgesScreen> {
  bool _isUploading = false;
  String _statusMessage = '';
  int _badgesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBadgeCount();
  }

  Future<void> _loadBadgeCount() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/store_badges.json');
      final List<dynamic> badges = jsonDecode(jsonString);
      setState(() {
        _badgesCount = badges.length;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _badgesCount = 0;
        _statusMessage = 'Error loading badges: $e\nMake sure assets/store_badges.json exists';
      });
    }
  }

  Future<void> _uploadBadges() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Uploading badges...';
    });

    try {
      // Load badges from JSON
      final String jsonString = await rootBundle.loadString('assets/store_badges.json');
      final List<dynamic> badgesJson = jsonDecode(jsonString);
      
      // Convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> badges = badgesJson
          .map((badge) => badge as Map<String, dynamic>)
          .toList();

      // Upload to Firestore
      await BadgeUploader.uploadBadgesFromList(badges);

      setState(() {
        _statusMessage = '✅ Successfully uploaded $_badgesCount badges to Firestore!';
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badges uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading badges: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
        title: const Text('Upload Badges'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'Badge Upload',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This will upload $_badgesCount badges to Firestore under:',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'store/badges',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('✅')
                      ? Colors.green[50]
                      : _statusMessage.contains('❌')
                          ? Colors.red[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusMessage.contains('✅')
                        ? Colors.green
                        : _statusMessage.contains('❌')
                            ? Colors.red
                            : Colors.blue,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('✅')
                        ? Colors.green[900]
                        : _statusMessage.contains('❌')
                            ? Colors.red[900]
                            : Colors.blue[900],
                  ),
                ),
              ),
            if (_statusMessage.isNotEmpty) const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadBadges,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Badges to Firestore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _loadBadgeCount(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Badge Count'),
            ),
          ],
        ),
      ),
    );
  }
}

