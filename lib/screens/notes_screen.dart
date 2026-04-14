import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../services/hive_service.dart';
import '../utils/helpers.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  void _openDialog(BuildContext ctx, {Note? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.content ?? '');

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(existing != null ? 'Edit Note' : 'New Safety Note',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),

            // Title field
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon:
                    Icon(Icons.title, color: Color(0xFFFF5352), size: 20),
              ),
            ),
            const SizedBox(height: 14),

            // Content field
            TextField(
              controller: bodyCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Safety details...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.notes_rounded,
                      color: Color(0xFFFF5352), size: 20),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Encryption badge
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 14, color: const Color(0xFF60DAC4)),
                const SizedBox(width: 6),
                const Text('Stored securely on device',
                    style: TextStyle(
                        color: Color(0xFF60DAC4),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5352),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  if (existing != null) {
                    existing
                      ..title = titleCtrl.text.trim()
                      ..content = bodyCtrl.text.trim()
                      ..time = DateTime.now();
                    await existing.save();
                  } else {
                    await HiveService.notes.add(Note(
                      title: titleCtrl.text.trim(),
                      content: bodyCtrl.text.trim(),
                      time: DateTime.now(),
                    ));
                  }
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                child: Text(
                    existing != null ? 'Update Note' : 'Save Note',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Note note) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () async {
              await note.delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      appBar: buildAppBar('Safety Notes'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    color: Color(0xFF60DAC4), size: 14),
                const SizedBox(width: 6),
                Text('Secure markers for your journey',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: HiveService.notes.listenable(),
                builder: (ctx, Box<Note> box, _) {
                  final notes = box.values.toList().reversed.toList();
                  if (notes.isEmpty) {
                    return buildEmptyState(
                        Icons.note_add_rounded,
                        'No safety notes yet.\nTap + to add your first note.');
                  }
                  return ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _noteCard(context, notes[i], i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        backgroundColor: const Color(0xFFFF5352),
        onPressed: () => _openDialog(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _noteCard(BuildContext ctx, Note n, int index) {
    final isPriority = index == 0;
    return GestureDetector(
      onTap: () => _openDialog(ctx, existing: n),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2026),
          borderRadius: BorderRadius.circular(18),
          border: isPriority
              ? const Border(
                  left: BorderSide(color: Color(0xFFFF5352), width: 3))
              : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                if (isPriority)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5352).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('PRIORITY',
                        style: TextStyle(
                            color: Color(0xFFFF5352),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ),
                const Spacer(),
                Text(formatTime(n.time),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                const SizedBox(width: 4),
                // Edit
                GestureDetector(
                  onTap: () => _openDialog(ctx, existing: n),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.white38),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: () => _confirmDelete(ctx, n),
                  child: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(n.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white)),
            // Content
            if (n.content.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(n.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}