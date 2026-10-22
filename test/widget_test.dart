import 'package:dsc26_flt_w02/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NourShelfApp shows stock alerts', (tester) async {
    await tester.pumpWidget(const NourShelfApp());
    await tester.pumpAndSettle();

    expect(find.text('Stock alerts'), findsOneWidget);
    expect(find.text('Insulin Glargine'), findsOneWidget);
  });
}
