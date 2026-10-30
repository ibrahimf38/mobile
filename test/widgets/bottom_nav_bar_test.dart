import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malimall/widgets/bottom_nav_bar.dart';

void main() {
  testWidgets('keeps the notification badge on the account destination',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainBottomNavBar(
            indexCourant: 0,
            badgeCompte: 3,
            onChanged: _noop,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Compte'), findsOneWidget);
    expect(
      tester.getCenter(find.text('3')).dx,
      greaterThan(tester.getCenter(find.text('Wallet')).dx),
    );
  });
}

void _noop(int _) {}
