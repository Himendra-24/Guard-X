import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/contact.dart';
import '../services/hive_service.dart';
import '../services/sos_service.dart';
import '../utils/helpers.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  void _openDialog(BuildContext ctx, {Contact? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    bool isPrimary = existing?.isPrimary ?? false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2026),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              // Sheet handle
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
                  Text(
                    existing != null ? 'Edit Contact' : 'Add Contact',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Name field
              _field(nameCtrl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),

              // Phone field
              _field(
                phoneCtrl,
                'Phone Number',
                Icons.phone_outlined,
                type: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Primary toggle
              GestureDetector(
                onTap: () => setSheetState(() => isPrimary = !isPrimary),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? const Color(0xFFFF5352).withOpacity(0.12)
                        : const Color(0xFF262A31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPrimary
                          ? const Color(0xFFFF5352).withOpacity(0.5)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPrimary
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isPrimary
                            ? const Color(0xFFFF5352)
                            : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary Contact',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isPrimary
                                    ? const Color(0xFFFF5352)
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Used first for SOS calls and alerts',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isPrimary,
                        activeColor: const Color(0xFFFF5352),
                        onChanged: (v) =>
                            setSheetState(() => isPrimary = v),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
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
                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) return;

                    // If marking as primary, unmark all others
                    if (isPrimary) {
                      for (final c in HiveService.contacts.values) {
                        if (c.isPrimary) {
                          c.isPrimary = false;
                          await c.save();
                        }
                      }
                    }

                    if (existing != null) {
                      existing
                        ..name = nameCtrl.text.trim()
                        ..phone = phoneCtrl.text.trim()
                        ..isPrimary = isPrimary;
                      await existing.save();
                    } else {
                      await HiveService.contacts.add(Contact(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        isPrimary: isPrimary,
                      ));
                    }
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                  child: Text(
                    existing != null ? 'Update Contact' : 'Save Contact',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: const Color(0xFFFF5352), size: 20),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, Contact c) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2026),
        title: const Text('Delete Contact'),
        content: Text(
          'Remove ${c.name} from your emergency contacts?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await c.delete();
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
      appBar: buildAppBar('Emergency Contacts'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Safety Circle',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  letterSpacing: 2),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: HiveService.contacts.listenable(),
                builder: (ctx, Box<Contact> box, _) {
                  final list = box.values.toList();
                  // Sort: primary first
                  list.sort((a, b) {
                    if (a.isPrimary && !b.isPrimary) return -1;
                    if (!a.isPrimary && b.isPrimary) return 1;
                    return 0;
                  });

                  if (list.isEmpty) {
                    return buildEmptyState(
                      Icons.group_add,
                      'No emergency contacts yet.\nTap "Add Contact" to get started.',
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _contactCard(context, list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'contacts_fab',
        backgroundColor: const Color(0xFFFF5352),
        onPressed: () => _openDialog(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Contact',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _contactCard(BuildContext ctx, Contact c) {
    final initials = c.name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.isPrimary
            ? const Color(0xFFFF5352).withOpacity(0.12)
            : const Color(0xFF1C2026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: c.isPrimary
              ? const Color(0xFFFF5352).withOpacity(0.35)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: c.isPrimary
                ? const Color(0xFFFF5352)
                : const Color(0xFF262A31),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: c.isPrimary
                    ? Colors.white
                    : const Color(0xFFA0CAFF),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.isPrimary) ...[
                      const SizedBox(width: 6),
                      _badge('⭐ Primary', const Color(0xFFFF5352)),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  c.phone,
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // Call button
          IconButton(
            onPressed: () => SOSService.callContact(c),
            icon: const Icon(Icons.call_rounded,
                color: Color(0xFF60DAC4)),
          ),

          // More options
          PopupMenuButton<String>(
            color: const Color(0xFF262A31),
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (val) async {
              if (val == 'edit') _openDialog(ctx, existing: c);
              if (val == 'primary') {
                // Unmark all, then mark this one
                for (final contact in HiveService.contacts.values) {
                  if (contact.isPrimary) {
                    contact.isPrimary = false;
                    await contact.save();
                  }
                }
                c.isPrimary = true;
                await c.save();
              }
              if (val == 'sms') {
                await SOSService.sendSMS(
                    c, 'Hi! Checking in via Guard-X Safety App.');
              }
              if (val == 'delete') _confirmDelete(ctx, c);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ]),
              ),
              PopupMenuItem(
                value: 'primary',
                child: Row(children: [
                  Icon(
                    c.isPrimary
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 18,
                    color: const Color(0xFFFF5352),
                  ),
                  const SizedBox(width: 8),
                  Text(c.isPrimary
                      ? 'Already Primary'
                      : 'Set as Primary'),
                ]),
              ),
              const PopupMenuItem(
                value: 'sms',
                child: Row(children: [
                  Icon(Icons.sms_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Send SMS'),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline,
                      size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold),
        ),
      );
}