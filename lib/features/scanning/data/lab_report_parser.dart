import '../domain/lab_result.dart';

/// Prototype parser for simple lines with a result and two range bounds.
/// Always verify extracted values against the original report.
class LabReportParser {
  static final RegExp _number = RegExp(r'-?\d+(?:[.,]\d+)?');
  List<LabResult> parse(String text) {
    final results = <LabResult>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      final matches = _number.allMatches(line).toList();
      if (line.length < 4 || matches.length < 3) continue;
      final nums = matches.map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.'))).whereType<double>().toList();
      if (nums.length < 3) continue;
      final value = nums.first, low = nums[nums.length - 2], high = nums.last;
      if (low >= high || low < 0 || high <= 0) continue;
      final name = line.substring(0, matches.first.start).trim();
      if (name.length < 2) continue;
      final unit = line.substring(matches.first.end, matches[1].start).trim();
      results.add(LabResult(name: name, value: value, unit: unit, referenceLow: low,
        referenceHigh: high, sourceLine: line));
    }
    return results;
  }
}
