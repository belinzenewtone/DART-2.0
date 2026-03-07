enum GlobalSearchKind {
  expense,
  income,
  task,
  event,
  budget,
  recurring,
}

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.kind,
    required this.primaryText,
    required this.secondaryText,
    required this.trailingText,
  });

  final GlobalSearchKind kind;
  final String primaryText;
  final String secondaryText;
  final String trailingText;
}
