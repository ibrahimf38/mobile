import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malimall/theme/colors.dart';
import 'package:malimall/widgets/app_feedback.dart';

void main() {
  testWidgets('shows feedback separately with the requested colors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  AppFeedback.error(context, 'Erreur détaillée');
                  AppFeedback.warning(context, 'Avertissement distinct');
                  AppFeedback.success(context, 'Opération réussie');
                },
                child: const Text('Afficher les messages'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher les messages'));
    await tester.pump();
    await tester.pumpAndSettle();

    _expectMessage(tester, 'Erreur détaillée', AppColors.accentOrange);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    _expectMessage(tester, 'Avertissement distinct', AppColors.accentOrange);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    _expectMessage(tester, 'Opération réussie', AppColors.statutTermineTexte);
  });
}

void _expectMessage(WidgetTester tester, String message, Color textColor) {
  final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
  expect(snackBar.backgroundColor, Colors.white);
  expect(find.text(message), findsOneWidget);
  expect(
    tester.widget<Text>(find.text(message)).style?.color,
    textColor,
  );
}
