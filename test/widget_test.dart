import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devforge_mobile/app.dart';

void main() {
testWidgets('DevForgeApp se construye correctamente', (WidgetTester tester) async {
await tester.pumpWidget(
const ProviderScope(
child: DevForgeApp(),
),
);

await tester.pumpAndSettle();

expect(find.byType(DevForgeApp), findsOneWidget);


});
}