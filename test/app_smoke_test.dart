import 'package:beltech/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders bottom navigation tabs', (tester) async {
    SharedPreferences.setMockInitialValues(
      <String, Object>{'onboarding_done_v1': true},
    );
    await tester
        .pumpWidget(const ProviderScope(child: PersonalManagementApp()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
