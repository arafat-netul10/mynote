import 'dart:async';

import 'package:flutter/material.dart';

import '../models/note_model.dart';
import '../repositories/note_repository.dart';

class NoteProvider extends ChangeNotifier {
  final NoteRepository _noteRepository;

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<NoteModel>>? _notesSubscription;

  NoteProvider({required this._noteRepository});

  List<NoteModel> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToNotes(String userId) {
    _notesSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _notesSubscription = _noteRepository
        .watchNotes(userId)
        .listen(
          (notes) {
            _notes = notes;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addNote({
    required String userId,
    required String title,
    required String description,
  }) async {
    await _execute(
      () => _noteRepository.createNote(
        userId: userId,
        title: title,
        description: description,
      ),
    );
  }

  Future<void> updateNote({
    required String userId,
    required NoteModel note,
  }) async {
    await _execute(
      () => _noteRepository.updateNote(userId: userId, note: note),
    );
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _execute(
      () => _noteRepository.deleteNote(userId: userId, noteId: noteId),
    );
  }

  Future<void> _execute(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
