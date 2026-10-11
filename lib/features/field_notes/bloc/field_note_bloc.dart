import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_note_event.dart';
import 'field_note_state.dart';
import '../../../repositories/field_note_repository.dart';

export 'field_note_event.dart';
export 'field_note_state.dart';

class FieldNoteBloc extends Bloc<FieldNoteEvent, FieldNoteState> {
  final FieldNoteRepository fieldNoteRepository;

  FieldNoteBloc({required this.fieldNoteRepository}) : super(FieldNoteInitial()) {
    on<LoadFieldNotes>(_onLoadFieldNotes);
    on<SaveFieldNoteEvent>(_onSaveFieldNote);
    on<DeleteFieldNoteEvent>(_onDeleteFieldNote);
  }

  Future<void> _onLoadFieldNotes(
    LoadFieldNotes event,
    Emitter<FieldNoteState> emit,
  ) async {
    emit(FieldNoteLoading());
    try {
      final notes = await fieldNoteRepository.getFieldNotes(
        siteId: event.siteId,
        customerId: event.customerId,
        status: event.status,
        query: event.query,
      );
      emit(FieldNoteLoaded(
        notes: notes,
        siteId: event.siteId,
        customerId: event.customerId,
        status: event.status,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(FieldNoteError(message: e.toString()));
    }
  }

  Future<void> _onSaveFieldNote(
    SaveFieldNoteEvent event,
    Emitter<FieldNoteState> emit,
  ) async {
    try {
      await fieldNoteRepository.saveFieldNote(event.note);
      emit(const FieldNoteActionSuccess(message: 'Field note saved successfully'));
      final notes = await fieldNoteRepository.getFieldNotes(siteId: event.note.siteId);
      emit(FieldNoteLoaded(notes: notes, siteId: event.note.siteId));
    } catch (e) {
      emit(FieldNoteError(message: e.toString()));
    }
  }

  Future<void> _onDeleteFieldNote(
    DeleteFieldNoteEvent event,
    Emitter<FieldNoteState> emit,
  ) async {
    try {
      await fieldNoteRepository.deleteFieldNote(event.id);
      emit(const FieldNoteActionSuccess(message: 'Field note deleted successfully'));
      final notes = await fieldNoteRepository.getFieldNotes();
      emit(FieldNoteLoaded(notes: notes));
    } catch (e) {
      emit(FieldNoteError(message: e.toString()));
    }
  }
}
