import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ReportService {
  static const int maxBytes = 15 * 1024 * 1024;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _reportsFor(String uid) =>
      _firestore.collection('users').doc(uid).collection('reports');

  Future<Map<String, dynamic>?> pickAndUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in first.');

    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (selection == null || selection.files.isEmpty) return null;

    final file = selection.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Could not read selected file.');
    }
    if (bytes.length > maxBytes) {
      throw Exception('File must be 15 MB or smaller.');
    }

    final name = file.name;
    final lower = name.toLowerCase();
    final contentType = lower.endsWith('.pdf')
        ? 'application/pdf'
        : lower.endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final reportId = _newId();
    final storagePath =
        'users/${user.uid}/reports/$reportId/$safeName';
    final storageRef = _storage.ref(storagePath);
    final reportRef = _reportsFor(user.uid).doc(reportId);

    await storageRef.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    try {
      final metadata = <String, dynamic>{
        'id': reportId,
        'ownerUid': user.uid,
        'storagePath': storagePath,
        'originalFileName': name,
        'contentType': contentType,
        'sizeBytes': bytes.length,
        'status': 'uploaded',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await reportRef.set(metadata);
      return metadata;
    } catch (_) {
      // Best-effort cleanup if the Firestore write fails after file upload.
      try {
        await storageRef.delete();
      } catch (_) {
        // Keep the original Firestore error for the caller.
      }
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> watchReports() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    return _reportsFor(user.uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> deleteReport(Map<String, dynamic> report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Please sign in first.');
    final reportId = report['id'] as String?;
    final storagePath = report['storagePath'] as String?;
    if (reportId == null || storagePath == null ||
        !storagePath.startsWith('users/${user.uid}/reports/')) {
      throw StateError('Invalid report record.');
    }
    // Delete metadata first so the report disappears from the UI.
    await _reportsFor(user.uid).doc(reportId).delete();
    try {
      await _storage.ref(storagePath).delete();
    } catch (_) {
      // In production, add a cleanup queue for failed object deletion.
    }
  }

  String _newId() {
    final random = Random.secure();
    return List.generate(24, (_) => random.nextInt(16).toRadixString(16)).join();
  }
}
