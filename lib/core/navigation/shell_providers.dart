import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for shell tab positions.
/// Update here if the tab order ever changes — all callers stay correct.
enum ShellTab {
  home,      // 0
  calendar,  // 1
  finance,   // 2
  tasks,     // 3
  assistant, // 4
  profile,   // 5
}

final shellTabIndexProvider = StateProvider<int>((_) => ShellTab.home.index);
