/// Pure numpad rules ported verbatim from `design/Expensy.html` (lines 237-241).
///
///   - Tapping a digit on '0' replaces it (no leading zeros).
///   - '.' only allowed once.
///   - Cap at 2 decimal places.
///   - Backspace decrements; collapses to '0' if string would become empty.
///
/// Kept as a free function so the controller stays trivial and these rules can
/// be unit-tested without a widget tree.
class AmountInput {
  AmountInput._();

  static String digit(String current, int d) {
    if (d < 0 || d > 9) return current;
    if (current == '0') return d.toString();

    // Enforce max 2 decimals.
    final dot = current.indexOf('.');
    if (dot != -1 && current.length - dot - 1 >= 2) return current;

    return '$current$d';
  }

  static String dot(String current) {
    if (current.contains('.')) return current;
    return '$current.';
  }

  static String backspace(String current) {
    if (current.length <= 1) return '0';
    return current.substring(0, current.length - 1);
  }

  static double parse(String current) => double.tryParse(current) ?? 0;

  static bool isValid(String current) => parse(current) > 0;
}
