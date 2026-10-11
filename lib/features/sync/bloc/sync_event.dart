import 'package:equatable/equatable.dart';
import '../../../models/sync_item.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class LoadSyncStatus extends SyncEvent {}

class TriggerSyncRequested extends SyncEvent {}

class RestoreDataRequested extends SyncEvent {}

class SyncStateUpdated extends SyncEvent {
  final List<SyncMutation> pendingMutations;
  final bool isSyncing;

  const SyncStateUpdated({
    required this.pendingMutations,
    required this.isSyncing,
  });

  @override
  List<Object?> get props => [pendingMutations, isSyncing];
}
