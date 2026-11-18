
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }


  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final noteProvider = context.read<NoteProvider>();

      if (_isEditing) {
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          updatedAt: DateTime.now(),
        );

        await noteProvider.updateNote(
          userId: userId,
          note: updatedNote,
        );
      } else {
        await noteProvider.addNote(
          userId: userId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }

      if (!mounted) return;

      // Stop the loading state before leaving this screen.
      setState(() => _isSaving = false);

      // Close the editor after a successful save.
      if (_isEditing) {
        Navigator.of(context).pop(
          widget.note!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }

    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveNote,
            icon: const Icon(Icons.save),
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
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
