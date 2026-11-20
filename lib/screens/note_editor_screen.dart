
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import '../services/notification/notification_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _reminderAt;
  bool _isSaving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.note?.description ?? '',
    );

    _reminderAt = widget.note?.reminderAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Generates a consistent notification ID from a Firestore note ID.
  int _notificationIdFor(String noteId) {
    var hash = 0x811c9dc5;

    for (final unit in noteId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }

    return hash & 0x7fffffff;
  }

  Future<void> _selectReminder() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt != null &&
          _reminderAt!.isAfter(now)
          ? _reminderAt!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) return;

    final initialTime = _reminderAt != null
        ? TimeOfDay.fromDateTime(_reminderAt!)
        : TimeOfDay.fromDateTime(now.add(
      const Duration(minutes: 5),
    ));

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime == null || !mounted) return;

    final reminder = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (reminder.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future reminder time.'),
        ),
      );
      return;
    }

    setState(() {
      _reminderAt = reminder;
    });
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_reminderAt != null &&
        !_reminderAt!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future reminder time.'),
        ),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final noteProvider = context.read<NoteProvider>();
      final notificationService = NotificationService.instance;

      // Request notification permission when a reminder is selected.
      if (_reminderAt != null) {
        final permissionGranted =
        await notificationService.requestPermission();

        if (!permissionGranted) {
          throw Exception(
            'Notification permission was not granted. '
                'Please enable notifications for MyNote.',
          );
        }
      }

      late final NoteModel savedNote;

      if (_isEditing) {
        savedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          updatedAt: DateTime.now(),
          reminderAt: _reminderAt,
          clearReminder: _reminderAt == null,
        );

        await noteProvider.updateNote(
          userId: userId,
          note: savedNote,
        );
      } else {
        savedNote = await noteProvider.addNote(
          userId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          reminderAt: _reminderAt,
        );
      }

      // Schedule or cancel the local notification.
      final notificationId = _notificationIdFor(savedNote.id);

      if (_reminderAt != null) {
        await notificationService.scheduleReminder(
          id: notificationId,
          title: savedNote.title,
          body: savedNote.description,
          scheduledDate: _reminderAt!,
        );
      } else {
        await notificationService.cancelReminder(notificationId);
      }

      if (!mounted) return;

      Navigator.of(context).pop(
        _isEditing ? savedNote : null,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatReminder(DateTime dateTime) {
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(dateTime);

    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );

    return '$date at $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Note' : 'New Note',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveNote,
            icon: const Icon(
              Icons.save,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter note title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Write your note here...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 8,
              maxLines: null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Reminder section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active),
                        SizedBox(width: 10),
                        Text(
                          'Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_reminderAt != null) ...[
                      Text(
                        _formatReminder(_reminderAt!),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const Text('No reminder set.'),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                            _isSaving ? null : _selectReminder,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _reminderAt == null
                                  ? 'Set Reminder'
                                  : 'Change',
                            ),
                          ),
                        ),
                        if (_reminderAt != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Remove reminder',
                            onPressed: _isSaving
                                ? null
                                : () {
                              setState(() {
                                _reminderAt = null;
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Note',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
