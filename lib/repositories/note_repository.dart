
import '../models/note_model.dart';

abstract class NoteRepository {
  Stream<List<NoteModel>> watchNotes(String userId);

  Future<NoteModel> createNote({
    required String userId,
    required String title,
    required String description,
  });

  Future<void> updateNote({
    required String userId,
    required NoteModel note,
  });

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  });
}
