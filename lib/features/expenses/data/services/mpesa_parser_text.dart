String normalizeParserText(String message) =>
    message.trim().replaceAll(RegExp(r'\s+'), ' ');

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
  return lower.contains('mpesa') ||
      lower.contains('m-pesa') ||
      (lower.contains('confirmed') && lower.contains('ksh'));
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
