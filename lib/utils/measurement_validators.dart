class MeasurementValidators {
  static String? label(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Nama profil wajib diisi.';
    }

    if (text.length > 80) {
      return 'Nama profil maksimal 80 karakter.';
    }

    return null;
  }

  static String? number(String? value, {bool isRequired = false}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return isRequired ? 'Ukuran ini wajib diisi.' : null;
    }

    if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(text)) {
      return 'Gunakan angka positif, maksimal 2 angka desimal.';
    }

    final number = double.tryParse(text.replaceAll(',', '.'));

    if (number == null || !number.isFinite || number <= 0 || number > 9999.99) {
      return 'Nilai harus lebih dari 0 hingga 9999,99.';
    }

    return null;
  }

  static double? parseOptional(String value) {
    final text = value.trim();

    if (text.isEmpty) return null;

    return double.parse(text.replaceAll(',', '.'));
  }
}
