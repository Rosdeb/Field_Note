import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sync_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/sync_item.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SyncBloc>().add(LoadSyncStatus());
  }

  void _handleSync() {
    context.read<SyncBloc>().add(TriggerSyncRequested());
  }

  Future<void> _handleFullRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Server'),
        content: const Text(
          'This will fetch all latest data from the backend server to ensure local data is completely up to date.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      context.read<SyncBloc>().add(RestoreDataRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SyncBloc, SyncState>(
      listener: (context, state) {
        if (state is SyncSuccessState) {
          FloatingSuccessBar.show(context, message: state.message);
        } else if (state is SyncFailureState) {
          FloatingErrorBar.show(context, message: state.error);
        }
      },
      builder: (context, state) {
        List<SyncMutation> pendingMutations = [];
        bool isSyncing = false;

        if (state is SyncLoaded) {
          pendingMutations = state.pendingMutations;
          isSyncing = state.isSyncing;
        }

        final hasPending = pendingMutations.isNotEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Sync Manager')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        hasPending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                        color: hasPending ? Colors.amber.shade800 : Colors.green,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Offline Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(
                              isSyncing
                                  ? 'Synchronizing with server...'
                                  : hasPending
                                      ? '${pendingMutations.length} change(s) waiting to sync'
                                      : 'All changes synced with server',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: isSyncing ? 'Syncing' : (hasPending ? 'Pending' : 'Synced'),
                        type: isSyncing
                            ? StatusBadgeType.info
                            : (hasPending ? StatusBadgeType.warning : StatusBadgeType.success),
                        icon: isSyncing ? Icons.sync : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (hasPending) ...[
                  const Text(
                    'Pending Operations',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pendingMutations.length,
                      itemBuilder: (context, index) {
                        final mutation = pendingMutations[index];
                        return AppCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                mutation.operation == SyncOperation.DELETE
                                    ? Icons.delete_outline
                                    : Icons.edit_note_outlined,
                                color: mutation.operation == SyncOperation.DELETE ? Colors.red : Colors.teal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${mutation.operation.name} ${mutation.entityType.name}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      'ID: ${mutation.entityId}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_done, size: 72, color: Colors.teal),
                        SizedBox(height: 16),
                        Text(
                          'Your local database is fully synchronized.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
                const SizedBox(height: 16),
                AppButton(
                  text: 'Sync Now',
                  isLoading: isSyncing,
                  icon: Icons.sync,
                  onPressed: isSyncing ? null : _handleSync,
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Restore Data from Server',
                  variant: AppButtonVariant.outline,
                  icon: Icons.cloud_download_outlined,
                  onPressed: isSyncing ? null : _handleFullRestore,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
