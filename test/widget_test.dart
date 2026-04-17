import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_agriculture_sliyeg/screens/login_screen.dart';

void main() {
  testWidgets('login screen shows main actions', (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp(child: LoginScreen()));

    expect(find.text('Smart Agriculture'), findsOneWidget);
    expect(find.text('Masuk ke akun'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Buat Akun Baru'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
