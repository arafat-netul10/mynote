
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import 'note_editor_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final NoteModel note;

  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteModel _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _editNote() async {
    final updatedNote = await Navigator.push<NoteModel>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: _note),
      ),
    );

    if (updatedNote != null && mounted) {
      setState(() {
        _note = updatedNote;
      });
    }
  }

  Future<void> _deleteNote() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text(
          'Are you sure you want to permanently delete this note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final userId = context.read<AuthProvider>().user?.id;

    if (userId == null) return;

    try {
      await context.read<NoteProvider>().deleteNote(
        userId: userId,
        noteId: _note.id,
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted successfully'),
        ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Details', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: _editNote,
            icon: const Icon(Icons.edit_outlined, color: Colors.white,),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: _deleteNote,
            icon: const Icon(Icons.delete_outline,color: Colors.white,),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Created: ${dateFormat.format(_note.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Updated: ${dateFormat.format(_note.updatedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 32),
            Text(
              _note.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
