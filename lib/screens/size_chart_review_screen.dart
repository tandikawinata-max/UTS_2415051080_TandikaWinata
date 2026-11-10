import 'dart:io';

import 'package:flutter/material.dart';

import '../models/reviewed_size_chart.dart';

class SizeChartReviewScreen extends StatefulWidget {
  final String imagePath;
  final String ocrText;
  final SizeChartDraft draft;
  final ReviewedSizeChart? initialChart;

  const SizeChartReviewScreen({
    super.key,
    required this.imagePath,
    required this.ocrText,
    required this.draft,
    this.initialChart,
  });

  @override
  State<SizeChartReviewScreen> createState() => _SizeChartReviewScreenState();
}

class _EditableSizeRow {
  final int id;
  SizeChartDraftRow value;

  _EditableSizeRow(this.id, this.value);
}

class _SizeChartReviewScreenState extends State<SizeChartReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rows = <_EditableSizeRow>[];

  ChartUnit? _unit;
  ChartMeasureType? _chestType;
  ChartMeasureType? _waistType;
  ChartMeasureType? _hipType;

  int _nextId = 0;
  bool _checked = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final previous = widget.initialChart;
    final sourceRows = previous?.inputRows ?? widget.draft.rows;

    _unit = previous?.unit;
    _chestType = previous?.chestType;
    _waistType = previous?.waistType;
    _hipType = previous?.hipType;

    for (final row in sourceRows) {
      _rows.add(_EditableSizeRow(_nextId++, row));
    }

    if (_rows.isEmpty) {
      _rows.add(_EditableSizeRow(_nextId++, const SizeChartDraftRow()));
    }
  }

  void _change(VoidCallback action) {
    setState(() {
      action();
      _checked = false;
      _errorMessage = null;
    });
  }

  void _save() {
    if (_submitted) {
      return;
    }

    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState!.validate();

    if (!valid || !_checked) {
      setState(() {
        _errorMessage = !valid
            ? 'Periksa kembali kolom yang ditandai.'
            : 'Centang konfirmasi setelah memeriksa tabel.';
      });
      return;
    }

    try {
      final chart = ReviewedSizeChart.confirm(
        sourceImagePath: widget.imagePath,
        sourceOcrText: widget.ocrText,
        unit: _unit!,
        chestType: _chestType!,
        waistType: _waistType,
        hipType: _hipType,
        rows: _rows.map((row) => row.value).toList(),
      );

      _submitted = true;
      Navigator.of(context).pop(chart);
    } on FormatException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    }
  }

  Widget _typeField({
    required String fieldKey,
    required String label,
    required ChartMeasureType? value,
    required bool requiredValue,
    required ValueChanged<ChartMeasureType?> onChanged,
  }) {
    return DropdownButtonFormField<ChartMeasureType>(
      key: ValueKey(fieldKey),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final type in ChartMeasureType.values)
          DropdownMenuItem(value: type, child: Text(type.label)),
      ],
      onChanged: onChanged,
      validator: (selected) {
        if (requiredValue && selected == null) {
          return 'Pilih jenis pengukuran.';
        }

        return null;
      },
    );
  }

  Widget _numberField(
    _EditableSizeRow row,
    String field,
    String label,
    String value,
    SizeChartDraftRow Function(String) update,
  ) {
    return TextFormField(
      key: ValueKey('${row.id}_$field'),
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: _unit?.symbol,
        border: const OutlineInputBorder(),
        errorMaxLines: 3,
      ),
      validator: (input) =>
          SizeChartRules.number(input, requiredValue: field == 'chest'),
      onChanged: (input) {
        _change(() {
          row.value = update(input);
        });
      },
    );
  }

  Widget _rowCard(_EditableSizeRow row) {
    return Card(
      key: ValueKey('sizeRow_${row.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('${row.id}_label'),
                    initialValue: row.value.label,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama ukuran *',
                      hintText: 'Contoh: S, M, XL, 38',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final error = SizeChartRules.label(value);

                      if (error != null) {
                        return error;
                      }

                      final key = SizeChartRules.labelKey(value!);
                      final duplicate = _rows.any(
                        (other) =>
                            other.id != row.id &&
                            SizeChartRules.labelKey(other.value.label) == key,
                      );

                      return duplicate ? 'Nama ukuran duplikat.' : null;
                    },
                    onChanged: (value) {
                      _change(() {
                        row.value = row.value.copyWith(label: value);
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus ukuran',
                  onPressed: _rows.length <= 1
                      ? null
                      : () {
                          _change(() {
                            _rows.removeWhere((item) => item.id == row.id);
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final columns = constraints.maxWidth >= 640
                    ? 4
                    : constraints.maxWidth >= 300
                    ? 2
                    : 1;

                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                final fields = [
                  _numberField(
                    row,
                    'chest',
                    'Dada *',
                    row.value.chest,
                    (value) => row.value.copyWith(chest: value),
                  ),
                  _numberField(
                    row,
                    'waist',
                    'Pinggang',
                    row.value.waist,
                    (value) => row.value.copyWith(waist: value),
                  ),
                  _numberField(
                    row,
                    'hip',
                    'Pinggul',
                    row.value.hip,
                    (value) => row.value.copyWith(hip: value),
                  ),
                  _numberField(
                    row,
                    'shoulder',
                    'Lebar bahu',
                    row.value.shoulder,
                    (value) => row.value.copyWith(shoulder: value),
                  ),
                ];

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final field in fields)
                      SizedBox(width: width, child: field),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWaist = _rows.any((row) => row.value.waist.trim().isNotEmpty);
    final hasHip = _rows.any((row) => row.value.hip.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Periksa tabel ukuran')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cocokkan setiap baris dengan gambar. '
                      'Nama ukuran dan dada wajib diisi. '
                      'Pinggang, pinggul, dan bahu boleh dikosongkan '
                      'jika tidak tercantum.',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: ExpansionTile(
                        title: const Text('Lihat gambar dan teks OCR'),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          Image.file(
                            File(widget.imagePath),
                            height: 280,
                            fit: BoxFit.contain,
                            cacheWidth: 1600,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'Gambar sumber tidak dapat ditampilkan.',
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            widget.ocrText.isEmpty
                                ? 'Teks OCR kosong. Isi tabel dari gambar.'
                                : widget.ocrText,
                          ),
                        ],
                      ),
                    ),
                    if (widget.initialChart == null &&
                        widget.draft.warnings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(widget.draft.warnings.join('\n\n')),
                    ],
                    const SizedBox(height: 24),
                    DropdownButtonFormField<ChartUnit>(
                      key: const ValueKey('chartUnit'),
                      initialValue: _unit,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Satuan pada gambar *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final unit in ChartUnit.values)
                          DropdownMenuItem(
                            value: unit,
                            child: Text(unit.label),
                          ),
                      ],
                      onChanged: (value) {
                        _change(() => _unit = value);
                      },
                      validator: (value) =>
                          value == null ? 'Pilih satuan.' : null,
                    ),
                    const SizedBox(height: 16),
                    _typeField(
                      fieldKey: 'chestType',
                      label: 'Jenis pengukuran dada *',
                      value: _chestType,
                      requiredValue: true,
                      onChanged: (value) {
                        _change(() => _chestType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _typeField(
                      fieldKey: 'waistType',
                      label: 'Jenis pinggang, jika diisi',
                      value: _waistType,
                      requiredValue: hasWaist,
                      onChanged: (value) {
                        _change(() => _waistType = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _typeField(
                      fieldKey: 'hipType',
                      label: 'Jenis pinggul, jika diisi',
                      value: _hipType,
                      requiredValue: hasHip,
                      onChanged: (value) {
                        _change(() => _hipType = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lebar bentang adalah lebar pakaian saat dibentangkan '
                      'rata. Nilainya dikalikan dua untuk menjadi lingkar. '
                      'Bahu selalu berupa lebar dan tidak dikalikan dua.\n\n'
                      'Masukkan angka asli pada gambar. '
                      'Konversi dilakukan setelah tabel dikonfirmasi.',
                    ),
                    const SizedBox(height: 24),
                    for (final row in _rows) _rowCard(row),
                    OutlinedButton.icon(
                      onPressed: () {
                        _change(() {
                          _rows.add(
                            _EditableSizeRow(
                              _nextId++,
                              const SizeChartDraftRow(),
                            ),
                          );
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah ukuran'),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      key: const ValueKey('confirmChartCheckbox'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _checked,
                      onChanged: (value) {
                        setState(() {
                          _checked = value ?? false;
                          _errorMessage = null;
                        });
                      },
                      title: const Text(
                        'Saya sudah mencocokkan angka, satuan, dan jenis '
                        'pengukuran dengan gambar. Tabel ini berisi ukuran '
                        'pakaian, bukan ukuran tubuh.',
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const ValueKey('saveReviewedChart'),
                      onPressed: _save,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Simpan tabel terverifikasi'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Perubahan diterapkan setelah tombol simpan ditekan. '
                      'Kembali tanpa menyimpan akan mengabaikan perubahan.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
