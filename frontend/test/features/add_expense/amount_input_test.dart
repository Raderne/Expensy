import 'package:expensy/features/add_expense/domain/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmountInput.digit', () {
    test('tapping a digit on "0" replaces it (no leading zeros)', () {
      expect(AmountInput.digit('0', 5), '5');
    });

    test('appends to a non-zero value', () {
      expect(AmountInput.digit('12', 3), '123');
    });

    test('caps decimal at 2 places', () {
      expect(AmountInput.digit('1.23', 4), '1.23');
      expect(AmountInput.digit('1.2', 3), '1.23');
    });
  });

  group('AmountInput.dot', () {
    test('appends a dot', () => expect(AmountInput.dot('12'), '12.'));
    test(
      'does not add a second dot',
      () => expect(AmountInput.dot('12.3'), '12.3'),
    );
    test('appends to "0"', () => expect(AmountInput.dot('0'), '0.'));
  });

  group('AmountInput.backspace', () {
    test('drops the last char', () {
      expect(AmountInput.backspace('123'), '12');
    });

    test('collapses single char to "0"', () {
      expect(AmountInput.backspace('5'), '0');
    });

    test('keeps "0" if already empty-ish', () {
      expect(AmountInput.backspace('0'), '0');
    });

    test('handles dot', () {
      expect(AmountInput.backspace('1.'), '1');
    });
  });

  group('AmountInput.isValid', () {
    test('zero is invalid', () => expect(AmountInput.isValid('0'), false));
    test('positive is valid', () => expect(AmountInput.isValid('1.99'), true));
    test(
      'trailing dot still parses',
      () => expect(AmountInput.isValid('5.'), true),
    );
  });
}
