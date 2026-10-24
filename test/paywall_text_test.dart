import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/core/utils/functions/app_functions.dart';

void main() {
  group('store price text', () {
    const lri = '\u2066';
    const pdi = '\u2069';

    test('Arabic-Indic digits and separators become 0-9 . ,', () {
      expect(AppFunctions.priceText('١٬٢٣٤٫٥٠ ر.س', currencyCode: 'SAR'), '${lri}1,234.50 ر.س$pdi');
    });

    test('US dollars show \$39.99 without "US"', () {
      expect(AppFunctions.priceText('US\$ ٣٩٫٩٩', currencyCode: 'USD'), '$lri\$39.99$pdi');
      expect(AppFunctions.priceText('US\$39.99', currencyCode: 'USD'), '$lri\$39.99$pdi');
      expect(AppFunctions.priceText('\$4.99', currencyCode: 'USD'), '$lri\$4.99$pdi');
    });

    test('other currencies keep what the store writes (CA\$, A\$, US\$ outside USD)', () {
      expect(AppFunctions.priceText('CA\$50.00', currencyCode: 'CAD'), '${lri}CA\$50.00$pdi');
      expect(AppFunctions.priceText('A\$ ٧٫٩٩', currencyCode: 'AUD'), '${lri}A\$ 7.99$pdi');
      expect(AppFunctions.priceText('US\$39.99'), '${lri}US\$39.99$pdi');
    });

    test('already plain prices stay as they are, in a left-to-right isolate', () {
      expect(AppFunctions.priceText('\$4.99'), '$lri\$4.99$pdi');
    });

    test('empty stays empty', () {
      expect(AppFunctions.priceText('  '), '');
    });
  });

  test('every language has the exit-offer wording for "no discount"', () {
    for (final lang in ['ar', 'de', 'en', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'pt']) {
      final strings = jsonDecode(File('assets/translations/$lang.json').readAsStringSync()) as Map<String, dynamic>;
      for (final key in ['exit_offer_title_plain', 'exit_offer_subtitle_plain', 'exit_offer_cta_plain']) {
        final text = strings[key] as String?;
        expect(text, isNotNull, reason: '$lang.$key');
        expect(text!.contains('%'), isFalse, reason: '$lang.$key must not mention a percentage');
      }
    }
  });
}
