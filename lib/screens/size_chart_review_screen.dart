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
  ChartBasis? _basis;
  ChartRangeMeaning? _rangeMeaning;
  ChartMeasureType? _chestType;
  ChartMeasureType? _waistType;
  ChartMeasureType? _hipType;

  int _nextId = 0;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final previous = widget.initialChart;
    final sourceRows = previous?.inputRows ?? widget.draft.rows;

    _unit = previous?.unit ?? widget.draft.unit;
    _basis = previous?.basis ?? widget.draft.basis;
    _rangeMeaning = previous?.rangeMeaning ?? widget.draft.rangeMeaning;
    _chestType = previous?.chestType ?? widget.draft.chestType;
    _waistType = previous?.waistType ?? widget.draft.waistType;
    _hipType = previous?.hipType ?? widget.draft.hipType;

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
      _errorMessage = null;
    });
  }

  void _save() {
    if (_submitted) {
      return;
    }

    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState!.validate();

    if (!valid) {
      setState(() {
        _errorMessage = 'Periksa kembali kolom yang ditandai.';
      });
      return;
    }

    try {
      final chart = ReviewedSizeChart.confirm(
        sourceImagePath: widget.imagePath,
        sourceOcrText: widget.ocrText,
        unit: _unit!,
        basis: _basis!,
        rangeMeaning: _rangeMeaning,
        chestType: _basis == ChartBasis.body ? null : _chestType,
        waistType: _basis == ChartBasis.body ? null : _waistType,
        hipType: _basis == ChartBasis.body ? null : _hipType,
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
      keyboardType: TextInputType.text,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: '94 atau 92 - 97',
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
    final hasWaist = _rows.any(
      (row) => !SizeChartRules.isEmptyValue(row.value.waist),
    );
    final hasHip = _rows.any(
      (row) => !SizeChartRules.isEmptyValue(row.value.hip),
    );
    final hasRange = _rows.any((row) => row.value.hasRange);
    final garment = _basis == ChartBasis.garment;

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
                      'Data terbaca sudah diisikan. Koreksi hanya bagian yang perlu. '
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
                    DropdownButtonFormField<ChartBasis>(
                      key: const ValueKey('chartBasis'),
                      initialValue: _basis,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Jenis tabel *',
                        border: OutlineInputBorder(),
                        errorMaxLines: 2,
                      ),
                      items: [
                        for (final value in ChartBasis.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                      ],
                      onChanged: (value) => _change(() => _basis = value),
                      validator: (value) => value == null
                          ? 'Pilih jenis tabel sesuai keterangan sumber.'
                          : null,
                    ),
                    const SizedBox(height: 16),
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
                    if (garment)
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
                    if (garment && hasWaist)
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
                    if (garment && hasHip)
                      _typeField(
                        fieldKey: 'hipType',
                        label: 'Jenis pinggul, jika diisi',
                        value: _hipType,
                        requiredValue: hasHip,
                        onChanged: (value) {
                          _change(() => _hipType = value);
                        },
                      ),
                    if (garment && hasRange) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ChartRangeMeaning>(
                        key: const ValueKey('rangeMeaning'),
                        initialValue: _rangeMeaning,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Makna rentang pakaian *',
                          border: OutlineInputBorder(),
                          errorMaxLines: 2,
                        ),
                        items: [
                          for (final value in ChartRangeMeaning.values)
                            DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                        ],
                        onChanged: (value) =>
                            _change(() => _rangeMeaning = value),
                        validator: (value) => value == null
                            ? 'Pilih makna rentang; tersedia pilihan belum diketahui.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      _basis == ChartBasis.body
                          ? 'Dada, pinggang, dan pinggul merupakan lingkar tubuh. Rentang dibandingkan langsung dengan profil tanpa tambahan kelonggaran. Bahu tetap lebar.'
                          : 'Lebar bentang pakaian dikalikan dua menjadi lingkar; bahu tidak dikalikan dua. Rentang regangan atau yang belum diketahui tidak langsung menjadi kandidat.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Angka tunggal dan rentang diterima, misalnya 94 atau 92 - 97. Gunakan angka asli; kedua batas dikonversi setelah dikonfirmasi.',
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
                    const Text(
                      'Gunakan angka asli pada screenshot. Dengan menekan Gunakan tabel ini, '
                      'Anda mengonfirmasi angka, satuan, dan jenis tabel yang ditampilkan.',
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
                      label: const Text('Gunakan tabel ini'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Perubahan diterapkan setelah tombol Gunakan tabel ini ditekan. '
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
