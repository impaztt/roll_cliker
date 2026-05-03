class NumberFormatter {
  static const _shortSuffixes = <String>['', 'K', 'M', 'B', 'T'];

  static String format(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) return '-${format(-value)}';
    if (value < 1000) return value.floor().toString();

    var v = value;
    var tier = 0;
    while (v >= 1000) {
      v /= 1000;
      tier++;
      if (tier >= _shortSuffixes.length + 26 * 26) break;
    }
    return '${v.toStringAsFixed(2)}${_suffix(tier)}';
  }

  static String formatPrecise(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) return '-${formatPrecise(-value)}';
    if (value < 1000) {
      if (value == value.truncateToDouble()) return value.toInt().toString();
      return value.toStringAsFixed(1);
    }
    return format(value);
  }

  static String formatInt(int value) {
    if (value == 0) return '0';
    final negative = value < 0;
    final s = (negative ? -value : value).toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return negative ? '-$buf' : buf.toString();
  }

  static String formatTime(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '$h시간 $m분';
    if (m > 0) return '$m분 $s초';
    return '$s초';
  }

  static String _suffix(int tier) {
    if (tier < _shortSuffixes.length) return _shortSuffixes[tier];
    final idx = tier - _shortSuffixes.length;
    final c1 = idx ~/ 26;
    final c2 = idx % 26;
    return '${String.fromCharCode(97 + c1)}${String.fromCharCode(97 + c2)}';
  }
}
