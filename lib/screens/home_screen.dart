
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_model.dart';
import '../providers/auth_provider.dart';
import '../providers/note_provider.dart';
import 'note_editor_screen.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<NoteProvider>().listenToNotes(userId);
      }
    });
  }

  Future<void> _logout() async {
    try {
      await context.read<AuthProvider>().signOut();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _openEditor() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NoteEditorScreen(),
      ),
    );
  }

  Future<void> _openNote(NoteModel note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(note: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteProvider = context.watch<NoteProvider>();
    final notes = noteProvider.notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyNote'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: noteProvider.isLoading && notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : noteProvider.errorMessage != null && notes.isEmpty
          ? Center(
        child: Text('Error: ${noteProvider.errorMessage}'),
      )
          : notes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                note.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openNote(note),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_alt_outlined,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Tap Add Note to create your first note.'),
          ],
        ),
      ),
    );
  }
}
