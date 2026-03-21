import 'package:flutter/material.dart';
import '../../core/models/timesheet_entry.dart';

class EntryTile extends StatelessWidget {
  final TimesheetEntry entry;
  const EntryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.progetto,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.orarioFormattato,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.durataFormattata,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
