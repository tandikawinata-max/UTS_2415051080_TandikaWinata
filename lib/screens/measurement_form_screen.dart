import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/body_measurement.dart';
import '../providers/measurement_provider.dart';
import '../utils/measurement_validators.dart';
import '../widgets/body_scan_entry_card.dart';

class MeasurementFormScreen extends StatefulWidget {
  final BodyMeasurement? initialMeasurement;

  const MeasurementFormScreen({super.key, this.initialMeasurement});

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _controllers = {
    'label': TextEditingController(),
    'chest': TextEditingController(),
    'waist': TextEditingController(),
    'hip': TextEditingController(),
    'shoulder': TextEditingController(),
    'height': TextEditingController(),
    'weight': TextEditingController(),
  };

  late final String _measurementId;
  late DateTime _measuredAt;

  bool get _isEditing => widget.initialMeasurement != null;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialMeasurement;

    _measurementId = initial?.id ?? const Uuid().v4();
    _measuredAt = initial?.measuredAt ?? DateTime.now();

    if (initial != null) {
      _controllers['label']!.text = initial.label;

      final values = {
        'chest': initial.chestCm,
        'waist': initial.waistCm,
        'hip': initial.hipCm,
        'shoulder': initial.shoulderWidthCm,
        'height': initial.heightCm,
        'weight': initial.weightKg,
      };

      for (final entry in values.entries) {
        _controllers[entry.key]!.text = _inputNumber(entry.value);
      }
    }
  }

  String _inputNumber(double? value) {
    if (value == null) return '';

    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  String get _dateText {
    final day = _measuredAt.day.toString().padLeft(2, '0');
    final month = _measuredAt.month.toString().padLeft(2, '0');

    return '$day/$month/${_measuredAt.year}';
  }

  double? _number(String key) {
    return MeasurementValidators.parseOptional(_controllers[key]!.text);
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(1900);
    final today = DateUtils.dateOnly(DateTime.now());
    final currentDate = DateUtils.dateOnly(_measuredAt);

    final initialDate = currentDate.isBefore(firstDate)
        ? firstDate
        : currentDate.isAfter(today)
        ? today
        : currentDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: today,
    );

    if (!mounted || picked == null) return;

    setState(() {
      _measuredAt = picked;
    });
  }

  Future<void> _save() async {
    final state = context.read<MeasurementProvider>();

    if (state.isSaving || state.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final measurement = BodyMeasurement(
      id: _measurementId,
      userId: widget.initialMeasurement?.userId,
      label: _controllers['label']!.text.trim(),
      chestCm: _number('chest')!,
      waistCm: _number('waist'),
      hipCm: _number('hip'),
      shoulderWidthCm: _number('shoulder'),
      heightCm: _number('height'),
      weightKg: _number('weight'),
      measuredAt: _measuredAt,
    );

    final saved = _isEditing
        ? await state.updateMeasurement(measurement)
        : await state.createMeasurement(measurement);

    if (!mounted || saved == null) return;

    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

    Navigator.of(context).pop(saved);
  }

  Widget _numberField({
    required String name,
    required String label,
    required bool enabled,
    bool isRequired = false,
    String unit = 'cm',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(name),
        controller: _controllers[name],
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : '$label (opsional)',
          suffixText: unit,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          return MeasurementValidators.number(value, isRequired: isRequired);
        },
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementProvider>();
    final busy = state.isSaving || state.isLoading;
    final theme = Theme.of(context);

    return PopScope<BodyMeasurement>(
      canPop: !state.isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Profil' : 'Tambah Profil'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isEditing) ...[
                        BodyScanEntryCard(returnToForm: true, enabled: !busy),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Isi ukuran tubuh hasil pengukuranmu. '
                        'Kolom bertanda * wajib diisi. '
                        'Desimal boleh menggunakan koma atau titik.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const ValueKey('label'),
                        controller: _controllers['label'],
                        enabled: !busy,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama profil *',
                          hintText: 'Contoh: Ukuran saya November',
                          border: OutlineInputBorder(),
                        ),
                        validator: MeasurementValidators.label,
                      ),
                      const SizedBox(height: 16),
                      _numberField(
                        name: 'chest',
                        label: 'Lingkar dada',
                        enabled: !busy,
                        isRequired: true,
                      ),
                      _numberField(
                        name: 'waist',
                        label: 'Lingkar pinggang',
                        enabled: !busy,
                      ),
                      _numberField(
                        name: 'hip',
                        label: 'Lingkar pinggul',
                        enabled: !busy,
                      ),
                      _numberField(
                        name: 'shoulder',
                        label: 'Lebar bahu',
                        enabled: !busy,
                      ),
                      _numberField(
                        name: 'height',
                        label: 'Tinggi badan',
                        enabled: !busy,
                      ),
                      _numberField(
                        name: 'weight',
                        label: 'Berat badan',
                        enabled: !busy,
                        unit: 'kg',
                      ),
                      OutlinedButton.icon(
                        onPressed: busy ? null : _pickDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('Tanggal pengukuran: $_dateText'),
                      ),
                      const SizedBox(height: 20),
                      if (state.saveErrorMessage != null) ...[
                        Text(
                          state.saveErrorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (state.isSaving) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 16),
                      ],
                      FilledButton.icon(
                        key: const ValueKey('saveMeasurement'),
                        onPressed: busy ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          state.isSaving
                              ? 'Menyimpan...'
                              : _isEditing
                              ? 'Simpan perubahan'
                              : 'Simpan profil',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
