import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinkly/core/utils/functions/app_functions.dart';

void main() {
  group('store price text', () {
    const lri = '⁦';
    const pdi = '⁩';

    test('Arabic-Indic digits and separators become 0-9 . ,', () {
      expect(AppFunctions.priceText('US\$ ٣٩٫٩٩'), '${lri}US\$ 39.99$pdi');
      expect(AppFunctions.priceText('١٬٢٣٤٫٥٠ ر.س'), '${lri}1,234.50 ر.س$pdi');
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
