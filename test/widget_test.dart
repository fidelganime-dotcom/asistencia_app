import 'package:flutter_test/flutter_test.dart';
import 'package:asistencia_app/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AsistenciaApp());
    expect(find.text('INGENIERIA DE SISTEMAS'), findsOneWidget);
  });
}
