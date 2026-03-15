import 'package:flutter_test/flutter_test.dart';
import 'package:rivly_app/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RivlyApp());
    // Verify the app builds successfully
    expect(find.text('Rivly'), findsAny);
  });
}
