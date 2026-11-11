/// Keeps both bounds without reducing a range to an average or endpoint.
/// Signed values are allowed here because analysis also uses this for differences.
/// Input validation belongs to SizeChartRules.
class MeasurementRange {
  final double min;
  final double max;
  final bool isRange;

  const MeasurementRange.single(double value)
    : min = value,
      max = value,
      isRange = false;

  const MeasurementRange.interval(this.min, this.max) : isRange = true;

  MeasurementRange scale(double factor) => isRange
      ? MeasurementRange.interval(min * factor, max * factor)
      : MeasurementRange.single(min * factor);

  MeasurementRange subtract(double value) => isRange
      ? MeasurementRange.interval(min - value, max - value)
      : MeasurementRange.single(min - value);

  String format({bool signed = false}) {
    String number(double value) {
      final rounded = value.abs() < 0.005 ? 0.0 : value;
      final text = rounded
          .toStringAsFixed(2)
          .replaceFirst(RegExp(r'\.?0+$'), '');
      return '${signed && rounded >= 0 ? '+' : ''}$text';
    }

    return isRange ? '${number(min)} – ${number(max)}' : number(min);
  }
}
