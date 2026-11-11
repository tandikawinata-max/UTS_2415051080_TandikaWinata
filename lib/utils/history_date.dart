String historyDate(DateTime date) {
  final d = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}.${two(d.minute)}';
}
