class LabResult {
  const LabResult({required this.name, required this.value, required this.unit,
    required this.referenceLow, required this.referenceHigh, required this.sourceLine});
  final String name;
  final double value, referenceLow, referenceHigh;
  final String unit, sourceLine;

  String get status => value < referenceLow ? 'Below range'
      : value > referenceHigh ? 'Above range' : 'Within range';

  String get explanation => value < referenceLow
      ? 'The extracted value is below the range parsed from this report. Verify OCR and discuss it with a clinician.'
      : value > referenceHigh
          ? 'The extracted value is above the range parsed from this report. Verify OCR and discuss it with a clinician.'
          : 'The extracted value falls within the parsed range. This alone does not establish that overall health is normal.';
}
