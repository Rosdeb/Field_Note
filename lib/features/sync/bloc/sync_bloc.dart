import 'package:flutter_bloc/flutter_bloc.dart';
import 'sync_event.dart';
import 'sync_state.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../repositories/sync_repository.dart';

export 'sync_event.dart';
export 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository syncRepository;
  final SyncManager syncManager;

  SyncBloc({
    required this.syncRepository,
    required this.syncManager,
  }) : super(SyncInitial()) {
    on<LoadSyncStatus>(_onLoadSyncStatus);
    on<TriggerSyncRequested>(_onTriggerSync);
    on<RestoreDataRequested>(_onRestoreData);
    on<SyncStateUpdated>(_onSyncStateUpdated);

    syncManager.isSyncingNotifier.addListener(_handleSyncingChanged);
  }

  void _handleSyncingChanged() {
    final mutations = syncRepository.getPendingMutations();
    add(SyncStateUpdated(
      pendingMutations: mutations,
      isSyncing: syncManager.isSyncingNotifier.value,
    ));
  }

  void _onLoadSyncStatus(
    LoadSyncStatus event,
    Emitter<SyncState> emit,
  ) {
    final mutations = syncRepository.getPendingMutations();
    emit(SyncLoaded(
      pendingMutations: mutations,
      isSyncing: syncManager.isSyncingNotifier.value,
    ));
  }

  void _onSyncStateUpdated(
    SyncStateUpdated event,
    Emitter<SyncState> emit,
  ) {
    emit(SyncLoaded(
      pendingMutations: event.pendingMutations,
      isSyncing: event.isSyncing,
    ));
  }

  Future<void> _onTriggerSync(
    TriggerSyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final initialMutations = syncRepository.getPendingMutations();
      final pushedCount = await syncRepository.triggerSync();
      final remainingMutations = syncRepository.getPendingMutations();

      if (pushedCount > 0 || initialMutations.isNotEmpty) {
        emit(SyncSuccessState(
          message: pushedCount > 0
              ? 'Successfully synced $pushedCount change(s) with the server!'
              : 'Sync completed successfully!',
        ));
      } else {
        emit(const SyncSuccessState(message: 'Database is already up to date.'));
      }

      emit(SyncLoaded(pendingMutations: remainingMutations, isSyncing: false));
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      emit(SyncFailureState(error: cleanMsg));
      final mutations = syncRepository.getPendingMutations();
      emit(SyncLoaded(pendingMutations: mutations, isSyncing: false));
    }
  }

  Future<void> _onRestoreData(
    RestoreDataRequested event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await syncRepository.restoreAllData();
      emit(const SyncSuccessState(message: 'All data restored from server!'));
      final mutations = syncRepository.getPendingMutations();
      emit(SyncLoaded(pendingMutations: mutations, isSyncing: false));
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '');
      emit(SyncFailureState(error: cleanMsg));
      final mutations = syncRepository.getPendingMutations();
      emit(SyncLoaded(pendingMutations: mutations, isSyncing: false));
    }
  }

  @override
  Future<void> close() {
    syncManager.isSyncingNotifier.removeListener(_handleSyncingChanged);
    return super.close();
  }
}
