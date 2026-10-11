abstract class FieldNoteFormEvent {
  const FieldNoteFormEvent();
}

class LoadFieldNoteForm extends FieldNoteFormEvent {
  final String? noteId;
  const LoadFieldNoteForm({this.noteId});
}

class SelectNoteCustomer extends FieldNoteFormEvent {
  final String customerId;
  const SelectNoteCustomer(this.customerId);
}

class SelectNoteSite extends FieldNoteFormEvent {
  final String siteId;
  const SelectNoteSite(this.siteId);
}

class SelectNoteStatus extends FieldNoteFormEvent {
  final String status;
  const SelectNoteStatus(this.status);
}

class SubmitFieldNoteForm extends FieldNoteFormEvent {
  final String title;
  final String notes;
  const SubmitFieldNoteForm({required this.title, required this.notes});
}
