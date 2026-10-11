import 'package:equatable/equatable.dart';
import '../../../models/field_note.dart';

abstract class FieldNoteState extends Equatable {
  const FieldNoteState();

  @override
  List<Object?> get props => [];
}

class FieldNoteInitial extends FieldNoteState {}

class FieldNoteLoading extends FieldNoteState {}

class FieldNoteLoaded extends FieldNoteState {
  final List<FieldNote> notes;
  final String? siteId;
  final String? customerId;
  final String? status;
  final String? searchQuery;

  const FieldNoteLoaded({
    required this.notes,
    this.siteId,
    this.customerId,
    this.status,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [notes, siteId, customerId, status, searchQuery];
}

class FieldNoteActionSuccess extends FieldNoteState {
  final String message;

  const FieldNoteActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class FieldNoteError extends FieldNoteState {
  final String message;

  const FieldNoteError({required this.message});

  @override
  List<Object?> get props => [message];
}
