/// Text and image coordinates retained for reconstructing table cells.
class OcrToken {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrToken({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get x => (left + right) / 2;
  double get y => (top + bottom) / 2;
  double get height => bottom - top;
}

class OcrDocument {
  final String text;
  final List<OcrToken> tokens;

  OcrDocument({required this.text, List<OcrToken> tokens = const []})
    : tokens = List.unmodifiable(tokens);
}
