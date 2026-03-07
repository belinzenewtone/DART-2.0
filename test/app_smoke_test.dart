import 'package:dart_2_0/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders bottom navigation tabs', (tester) async {
    await tester
        .pumpWidget(const ProviderScope(child: PersonalManagementApp()));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
