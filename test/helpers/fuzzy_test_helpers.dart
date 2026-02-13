import 'dart:math';

/// Generates a random printable ASCII string (0x20–0x7E).
String randomText(Random rng, int minLen, int maxLen) {
  final length = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(length, (_) => 0x20 + rng.nextInt(0x7E - 0x20 + 1)),
  );
}

/// Returns a random contiguous substring of [text] with length >= 1.
String randomSubstring(Random rng, String text) {
  final start = rng.nextInt(text.length);
  final maxLen = text.length - start;
  final length = 1 + rng.nextInt(maxLen);
  return text.substring(start, start + length);
}

/// Returns a random non-contiguous subsequence of [text] with length >= 1.
///
/// Each character is included with 50% probability. If the result is empty,
/// a single random character is returned.
String randomSubsequence(Random rng, String text) {
  final buf = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (rng.nextBool()) buf.write(text[i]);
  }
  if (buf.isEmpty) {
    buf.write(text[rng.nextInt(text.length)]);
  }
  return buf.toString();
}

/// Applies [edits] random mutations (insertion, deletion, substitution).
String applyEdits(Random rng, String text, int edits) {
  var result = text;
  for (var i = 0; i < edits; i++) {
    if (result.isEmpty) {
      final ch = String.fromCharCode(0x61 + rng.nextInt(26));
      result = ch;
      continue;
    }
    final editType = rng.nextInt(3);
    final pos = rng.nextInt(result.length);
    switch (editType) {
      case 0: // insertion
        final ch = String.fromCharCode(0x61 + rng.nextInt(26));
        result = result.substring(0, pos) + ch + result.substring(pos);
      case 1: // deletion
        result = result.substring(0, pos) + result.substring(pos + 1);
      case 2: // substitution
        final ch = String.fromCharCode(0x61 + rng.nextInt(26));
        result = result.substring(0, pos) + ch + result.substring(pos + 1);
    }
  }
  return result;
}
