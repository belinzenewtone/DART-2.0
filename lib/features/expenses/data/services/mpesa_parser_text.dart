String normalizeParserText(String message) => message
    .trim()
    // Normalize non-breaking spaces to regular spaces.
    .replaceAll('\u00A0', ' ')
    // Remove zero-width chars entirely to avoid splitting tokens.
    .replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF]'), '')
    // Normalize curly quotes and dashes used by some SMS gateways.
    .replaceAll('\u2019', "'")
    .replaceAll('\u2018', "'")
    .replaceAll('\u201C', '"')
    .replaceAll('\u201D', '"')
    .replaceAll('\u2013', '-')
    .replaceAll('\u2014', '-')
    // Collapse any run of whitespace (including newlines) to a single space.
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String titleCaseWords(String text) => text
    .split(' ')
    .map(
      (part) => part.isEmpty
          ? part
          : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
    )
    .join(' ');

bool looksLikeMpesaMessage(String message) {
  final lower = message.toLowerCase();
  final hasTxCode =
      RegExp(r'^[a-z0-9]{10}\b', caseSensitive: false).hasMatch(message.trim());
  return lower.contains('mpesa') ||
      lower.contains('m-pesa') ||
      (lower.contains('confirmed') &&
          (lower.contains('ksh') || lower.contains('kes') || hasTxCode));
}

DateTime? parseMpesaDateTime(String message, RegExp dateTimePattern) {
  final match = dateTimePattern.firstMatch(message);
  if (match == null) return null;
  final date = match.group(1)?.split('/');
  final time = match.group(2);
  if (date == null || date.length != 3 || time == null) return null;
  final day = int.tryParse(date[0]);
  final month = int.tryParse(date[1]);
  var year = int.tryParse(date[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 100) year += 2000;
  final timeMatch = RegExp(
    r'^(\d{1,2}):(\d{2})\s?(am|pm)$',
    caseSensitive: false,
  ).firstMatch(time.trim());
  if (timeMatch == null) return null;
  var hour = int.parse(timeMatch.group(1)!);
  final minute = int.parse(timeMatch.group(2)!);
  final meridiem = timeMatch.group(3)!.toLowerCase();
  if (meridiem == 'pm' && hour < 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  return DateTime(year, month, day, hour, minute);
}
