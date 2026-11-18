
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note_model.dart';
import 'note_repository.dart';

class FirestoreNoteRepository implements NoteRepository {
  final FirebaseFirestore _firestore;

  FirestoreNoteRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notesCollection(
      String userId,
      ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes');
  }

  @override
  Stream<List<NoteModel>> watchNotes(String userId) {
    return _notesCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteModel.fromMap({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();
    });
  }

  @override
  Future<NoteModel> createNote({
    required String userId,
    required String title,
    required String description,
  }) async {
    final now = DateTime.now();

    final docRef = _notesCollection(userId).doc();

    final note = NoteModel(
      id: docRef.id,
      title: title.trim(),
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(note.toMap());

    return note;
  }

  @override
  Future<void> updateNote({
    required String userId,
    required NoteModel note,
  }) async {
    await _notesCollection(userId).doc(note.id).update({
      'title': note.title.trim(),
      'description': note.description.trim(),
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _notesCollection(userId).doc(noteId).delete();
  }
}
