import 'package:equatable/equatable.dart';
import '../../../models/sync_item.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncLoaded extends SyncState {
  final List<SyncMutation> pendingMutations;
  final bool isSyncing;

  const SyncLoaded({
    required this.pendingMutations,
    this.isSyncing = false,
  });

  @override
  List<Object?> get props => [pendingMutations, isSyncing];
}

class SyncSuccessState extends SyncState {
  final String message;

  const SyncSuccessState({required this.message});

  @override
  List<Object?> get props => [message];
}

class SyncFailureState extends SyncState {
  final String error;

  const SyncFailureState({required this.error});

  @override
  List<Object?> get props => [error];
}
