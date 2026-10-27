import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../data/lab_report_parser.dart';
import '../domain/lab_result.dart';

class ReportHomeScreen extends StatefulWidget {
  const ReportHomeScreen({super.key});
  @override
  State<ReportHomeScreen> createState() => _ReportHomeScreenState();
}
class _ReportHomeScreenState extends State<ReportHomeScreen> {
  final _picker = ImagePicker();
  final _ocr = TextRecognizer(script: TextRecognitionScript.latin);
  bool _busy = false;
  String? _imagePath, _error;
  String _text = '';
  List<LabResult> _results = [];
  @override
  void dispose() { _ocr.close(); super.dispose(); }

  Future<void> _scan(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 95);
      if (file == null) return;
      setState(() { _busy = true; _error = null; _imagePath = file.path; _text = ''; _results = []; });
      final recognized = await _ocr.processImage(InputImage.fromFilePath(file.path));
      if (!mounted) return;
      setState(() { _text = recognized.text; _results = LabReportParser().parse(recognized.text); });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not scan this image. Try a clear, well-lit photo. ($e)');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Signed in';
    return Scaffold(
      appBar: AppBar(title: const Text('BloodSenz'),
        actions: [IconButton(tooltip: 'Sign out', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Hello, $email', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Scan a blood report', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Choose a clear report image. Text recognition runs on-device. Verify extracted values against the original report.'),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: _busy ? null : () => _scan(ImageSource.camera),
            icon: const Icon(Icons.document_scanner_outlined), label: const Text('Capture report'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _scan(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined), label: const Text('Choose image'))),
        ]),
        if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: Column(children: [
          CircularProgressIndicator(), SizedBox(height: 12), Text('Reading report text…')]))),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
        if (_imagePath != null) ...[const SizedBox(height: 20), ClipRRect(borderRadius: BorderRadius.circular(14),
          child: Image.file(File(_imagePath!), height: 220, fit: BoxFit.contain))],
        if (_text.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text('Extracted results', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Prototype parser: only simple rows with a numeric value and reference range may be shown.'),
          if (_results.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No structured rows found. Review the recognized text below; this report layout may need a better parser.')),
          ..._results.map(_resultCard),
          ExpansionTile(title: const Text('Review all recognized text'),
            children: [Padding(padding: const EdgeInsets.all(12), child: SelectableText(_text))]),
        ],
        const SizedBox(height: 20),
        const Card(child: Padding(padding: EdgeInsets.all(14), child: Text(
          'Important: BloodSenz is an informational prototype, not a diagnostic tool. OCR can misread numbers and ranges. Verify every result with the original report and consult a qualified healthcare professional.'))),
      ]),
    );
  }

  Widget _resultCard(LabResult r) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 6),
      Text('Extracted value: ${r.value} ${r.unit}'.trim()),
      Text('Parsed reference range: ${r.referenceLow}–${r.referenceHigh} ${r.unit}'.trim()),
      const SizedBox(height: 6),
      Text(r.status, style: TextStyle(fontWeight: FontWeight.bold,
        color: r.status == 'Within range' ? Colors.teal : Colors.deepOrange)),
      const SizedBox(height: 6), Text(r.explanation),
      ExpansionTile(tilePadding: EdgeInsets.zero, title: const Text('Source line (verify OCR)'),
        children: [Align(alignment: Alignment.centerLeft, child: SelectableText(r.sourceLine))]),
    ]),
  ));
}
