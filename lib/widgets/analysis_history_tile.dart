import 'package:flutter/material.dart';
import '../models/analysis_history.dart';
import '../screens/analysis_history_detail_screen.dart';
import '../utils/history_date.dart';

class AnalysisHistoryTile extends StatelessWidget {
  final AnalysisHistorySummary entry;
  const AnalysisHistoryTile({super.key, required this.entry});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey('history_${entry.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.checkroom,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        entry.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '${entry.recommendation}\n${entry.profileLabel} · ${entry.basis.label}\n${historyDate(entry.createdAt)}',
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openAnalysisHistoryDetail(context, entry.id),
    ),
  );
}
