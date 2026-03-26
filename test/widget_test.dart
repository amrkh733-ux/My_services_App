import 'package:flutter_test/flutter_test.dart';
import 'package:phone_store_flutter/main.dart';
//import 'package:projectaladimi1/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App loads without errors', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
