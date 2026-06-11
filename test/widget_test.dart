import 'package:flutter_test/flutter_test.dart';
import 'package:project/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TaskFlowApp());
    expect(find.byType(TaskFlowApp), findsOneWidget);
  });
}
