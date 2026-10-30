import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:malimall/core/models/catalogue_models.dart';
import 'package:malimall/widgets/product_card.dart';

void main() {
  testWidgets('fits a compact similar-product card with larger text',
      (tester) async {
    const produit = ProduitResponse(
      id: 1,
      boutiqueId: 1,
      nom: 'Produit en promotion',
      description: null,
      prixMmc: 2500,
      stock: 5,
      categorie: 'Accessoires',
      actif: true,
      imageUrl: null,
      quantiteVendue: 12,
      enPromotion: true,
      promoPrixMmc: 2000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 130,
                height: 196,
                child: ProductCard(produit: produit, onTap: _noop),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
