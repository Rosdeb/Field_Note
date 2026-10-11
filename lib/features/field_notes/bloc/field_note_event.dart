import 'package:equatable/equatable.dart';
import '../../../models/field_note.dart';

abstract class FieldNoteEvent extends Equatable {
  const FieldNoteEvent();

  @override
  List<Object?> get props => [];
}

class LoadFieldNotes extends FieldNoteEvent {
  final String? siteId;
  final String? customerId;
  final String? status;
  final String? query;

  const LoadFieldNotes({
    this.siteId,
    this.customerId,
    this.status,
    this.query,
  });

  @override
  List<Object?> get props => [siteId, customerId, status, query];
}

class SaveFieldNoteEvent extends FieldNoteEvent {
  final FieldNote note;

  const SaveFieldNoteEvent({required this.note});

  @override
  List<Object?> get props => [note];
}

class DeleteFieldNoteEvent extends FieldNoteEvent {
  final String id;

  const DeleteFieldNoteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
