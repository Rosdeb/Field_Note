import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/field_note_bloc.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/field_note.dart';
import '../../../routes/app_router.dart';

class FieldNotesScreen extends StatefulWidget {
  const FieldNotesScreen({super.key});

  @override
  State<FieldNotesScreen> createState() => _FieldNotesScreenState();
}

class _FieldNotesScreenState extends State<FieldNotesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<FieldNoteBloc>().add(const LoadFieldNotes());
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    context.read<FieldNoteBloc>().add(LoadFieldNotes(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              hintText: 'Search field notes...',
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
          Expanded(
            child: BlocConsumer<FieldNoteBloc, FieldNoteState>(
              listener: (context, state) {
                if (state is FieldNoteActionSuccess) {
                  FloatingSuccessBar.show(context, message: state.message);
                } else if (state is FieldNoteError) {
                  FloatingErrorBar.show(context, message: state.message);
                }
              },
              builder: (context, state) {
                if (state is FieldNoteLoading) {
                  return const LoadingView(message: 'Loading field notes...');
                }

                if (state is FieldNoteLoaded) {
                  final notes = state.notes;
                  if (notes.isEmpty) {
                    return EmptyView(
                      icon: Icons.note_alt_outlined,
                      title: _searchQuery.isEmpty ? 'No Field Notes Yet' : 'No Matching Notes',
                      subtitle: _searchQuery.isEmpty
                          ? 'Create notes during your site visits and inspections.'
                          : 'Try adjusting your search terms.',
                      actionText: 'Create Field Note',
                      onActionPressed: () => context.push(AppRouter.fieldNoteForm),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<SyncBloc>().add(TriggerSyncRequested());
                      context.read<FieldNoteBloc>().add(LoadFieldNotes(query: _searchQuery));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return AppCard(
                          onTap: () => context.push(AppRouter.fieldNoteForm, extra: note.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  StatusBadge(
                                    label: note.isSynced ? 'Synced' : 'Pending',
                                    type: note.isSynced ? StatusBadgeType.success : StatusBadgeType.warning,
                                    icon: note.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                  ),
                                  IconButton(
                                    icon: Image.asset("assets/icons/trash (1).png", height: 20, color: Colors.redAccent),
                                    onPressed: () => _deleteNote(note),
                                  ),
                                ],
                              ),
                              if (note.notes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  note.notes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Image.asset("assets/icons/calendar.png", height: 13, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  if (note.photos.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.photo_outlined, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text('${note.photos.length}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.fieldNoteForm),
        elevation: 2,
        tooltip: 'Create Field Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteNote(FieldNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Field Note'),
        content: Text('Are you sure you want to delete "${note.title}"? This will queue for sync.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<FieldNoteBloc>().add(DeleteFieldNoteEvent(id: note.id));
    }
  }

}
