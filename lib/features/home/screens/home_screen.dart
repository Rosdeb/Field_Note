import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routes/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Notes'),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, syncState) {
              int pendingCount = 0;
              if (syncState is SyncLoaded) {
                pendingCount = syncState.pendingMutations.length;
              }
              return IconButton(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.sync),
                ),
                tooltip: 'Sync',
                onPressed: () => context.push(AppRouter.sync),
              );
            },
          ),
          IconButton(
            icon: Image.asset(
              "assets/icons/settings.png",
              height: 24,
              width: 21,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRouter.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, syncState) {
              int pendingCount = 0;
              bool isSyncing = false;
              if (syncState is SyncLoaded) {
                pendingCount = syncState.pendingMutations.length;
                isSyncing = syncState.isSyncing;
              }
              final hasPending = pendingCount > 0;

              final Color statusColor = isSyncing
                  ? theme.colorScheme.primary
                  : (hasPending ? Colors.amber.shade800 : Colors.green);

              final Color statusBgColor = isSyncing
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : (hasPending
                      ? Colors.amber.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.12));

              final IconData statusIcon = isSyncing
                  ? Icons.cloud_sync_outlined
                  : (hasPending
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined);

              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                onTap: () => context.push(AppRouter.sync),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync Status',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSyncing
                                ? 'Syncing changes with server...'
                                : hasPending
                                    ? '$pendingCount change(s) stored locally offline'
                                    : 'All local notes are up to date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: isSyncing
                          ? 'Syncing'
                          : (hasPending ? 'Pending ($pendingCount)' : 'Synced'),
                      type: isSyncing
                          ? StatusBadgeType.info
                          : (hasPending ? StatusBadgeType.warning : StatusBadgeType.success),
                      icon: isSyncing
                          ? Icons.sync
                          : (hasPending ? Icons.cloud_upload_outlined : Icons.check_circle_outline),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MenuActionCard(
            title: 'Field Notes',
            subtitle: 'View, filter, and document site inspection notes',
            icon: "assets/icons/writing.png",
            onTap: () => context.push(AppRouter.fieldNotes),
          ),
          _MenuActionCard(
            title: 'Customers',
            subtitle: 'Manage client accounts and contact persons',
            icon: "assets/icons/stats.png",
            onTap: () => context.push(AppRouter.customers),
          ),
          _MenuActionCard(
            title: 'Sites',
            subtitle: 'Explore site locations and geo-coordinates',
            icon: "assets/icons/location (1).png",
            onTap: () => context.push(AppRouter.sites),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.fieldNoteForm),
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}

class _MenuActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;

  const _MenuActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 13,vertical: 11),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(icon, height: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
