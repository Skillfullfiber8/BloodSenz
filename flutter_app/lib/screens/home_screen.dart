import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/report_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _upload() async {
    setState(() { _busy = true; _message = null; });
    try {
      final report = await ReportService().pickAndUpload();
      if (mounted) setState(() => _message = report == null
          ? 'Upload cancelled.'
          : 'Uploaded ${report['originalFileName'] ?? 'report'} successfully.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> report) async {
    final name = report['originalFileName'] as String? ?? 'this report';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('Delete "$name" from your account? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ReportService().deleteReport(report);
      if (mounted) setState(() => _message = 'Report deleted.');
    } catch (e) {
      if (mounted) setState(() => _message = 'Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BloodSenz', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF18324A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_rounded, color: Color(0xFF68DED3), size: 34),
                  SizedBox(height: 18),
                  Text('Understand your\nhealth reports.', style: TextStyle(
                    color: Colors.white, fontSize: 28, height: 1.15, fontWeight: FontWeight.w800)),
                  SizedBox(height: 10),
                  Text('Keep your lab reports organized and explore their results in plain language.',
                    style: TextStyle(color: Colors.white70, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Welcome${user?.email == null ? '' : ', ${user!.email}'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Your reports are private to your account.'),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.upload_file_rounded, size: 32, color: Color(0xFF16A6A1)),
                  const SizedBox(height: 12),
                  const Text('Add a blood report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Choose a PDF, JPG, or PNG file up to 15 MB.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: _busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_rounded),
                    label: Text(_busy ? 'Uploading…' : 'Choose report'),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, style: TextStyle(color: _message!.startsWith('Upload failed') ? Colors.red : Colors.black87)),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('Your reports',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ReportService().watchReports(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Card(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Could not load reports. Check your Firebase setup and Firestore rules.')));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()));
                }
                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return const Card(child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No reports yet. Upload a report to get started.')));
                }
                return Column(
                  children: reports.map((report) {
                    final name = report['originalFileName'] as String? ?? 'Blood report';
                    final timestamp = report['createdAt'];
                    final dateText = timestamp is Timestamp
                        ? timestamp.toDate().toLocal().toString().split('.').first
                        : 'Recently uploaded';
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.description_outlined)),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$dateText • ${report['status'] ?? 'uploaded'}'),
                        trailing: IconButton(
                          tooltip: 'Delete report',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(report),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF16A6A1)),
                  SizedBox(width: 12),
                  Expanded(child: Text('BloodSenz is a report-organization and wellness-support concept, not a diagnostic tool. Always discuss medical concerns with a qualified healthcare professional.')),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
