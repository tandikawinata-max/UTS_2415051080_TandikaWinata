import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_history.dart';
import '../models/size_analysis_result.dart';
import '../providers/analysis_history_provider.dart';
import '../screens/analysis_history_detail_screen.dart';

class AnalysisSaveCard extends StatefulWidget {
  final SizeAnalysisResult result;
  const AnalysisSaveCard({super.key, required this.result});
  @override
  State<AnalysisSaveCard> createState() => _AnalysisSaveCardState();
}

class _AnalysisSaveCardState extends State<AnalysisSaveCard> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  @override
  void initState() {
    super.initState();
    final history = context.read<AnalysisHistoryProvider>();
    final defaultTitle = 'Analisis ${widget.result.profile.label}';
    _title = TextEditingController(
      text:
          history.pendingFor(widget.result.id)?.title ??
          history.savedFor(widget.result.id)?.title ??
          String.fromCharCodes(defaultTitle.runes.take(80)),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final history = context.read<AnalysisHistoryProvider>();
    final draft =
        history.pendingFor(widget.result.id) ??
        AnalysisHistoryDraft(
          id: widget.result.id,
          title: _title.text,
          snapshot: AnalysisSnapshot.fromResult(widget.result),
        );
    final saved = await history.save(draft);
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('“${saved.title}” tersimpan di riwayat.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AnalysisHistoryProvider>();
    final saved = history.savedFor(widget.result.id);
    final pending = history.pendingFor(widget.result.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                saved == null
                    ? 'Simpan untuk dilihat kembali'
                    : 'Hasil sudah tersimpan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('historyTitle'),
                controller: _title,
                enabled: !history.isBusy && saved == null && pending == null,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nama produk atau analisis',
                  hintText: 'Contoh: Kemeja linen toko A',
                ),
                validator: AnalysisHistoryDraft.titleError,
              ),
              if (history.saveErrorId == widget.result.id &&
                  history.saveError != null) ...[
                Text(
                  history.saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                key: const ValueKey('saveAnalysis'),
                onPressed: saved != null || history.isBusy ? null : _save,
                icon: Icon(
                  saved != null
                      ? Icons.check_circle_outline
                      : Icons.bookmark_add_outlined,
                ),
                label: Text(
                  saved != null
                      ? 'Tersimpan'
                      : history.isSaving
                      ? 'Menyimpan...'
                      : pending != null
                      ? 'Coba simpan lagi'
                      : 'Simpan hasil',
                ),
              ),
              if (saved != null)
                TextButton(
                  onPressed: () => openAnalysisHistoryDetail(context, saved.id),
                  child: const Text('Lihat detail tersimpan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
