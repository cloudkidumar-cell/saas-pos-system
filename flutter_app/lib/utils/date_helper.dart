DateTime parseDateTime(String dateStr) {
  if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
    dateStr = '${dateStr}Z';
  }
  return DateTime.parse(dateStr).toLocal();
}
