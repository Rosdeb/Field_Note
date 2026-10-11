import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/site_bloc.dart';
import '../../sync/bloc/sync_bloc.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/site.dart';
import '../../../routes/app_router.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(const LoadSites());
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    context.read<SiteBloc>().add(LoadSites(query: query));
  }

  Future<void> _deleteSite(Site site) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete ${site.name}? This will queue for sync.'),
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
      context.read<SiteBloc>().add(DeleteSiteEvent(id: site.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppSearchBar(
              hintText: 'Search sites...',
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          ),
          Expanded(
            child: BlocConsumer<SiteBloc, SiteState>(
              listener: (context, state) {
                if (state is SiteActionSuccess) {
                  FloatingSuccessBar.show(context, message: state.message);
                } else if (state is SiteError) {
                  FloatingErrorBar.show(context, message: state.message);
                }
              },
              builder: (context, state) {
                if (state is SiteLoading) {
                  return const LoadingView(message: 'Loading sites...');
                }

                if (state is SiteLoaded) {
                  final sites = state.sites;
                  if (sites.isEmpty) {
                    return EmptyView(
                      icon: Icons.location_on_outlined,
                      title: _searchQuery.isEmpty ? 'No Sites Found' : 'No Matching Sites',
                      subtitle: _searchQuery.isEmpty
                          ? 'Create a site to record inspections and geolocations.'
                          : 'Try adjusting your search terms.',
                      actionText: 'Add Site',
                      onActionPressed: () => context.push(AppRouter.siteForm),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<SyncBloc>().add(TriggerSyncRequested());
                      context.read<SiteBloc>().add(LoadSites(query: _searchQuery));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: sites.length,
                      itemBuilder: (context, index) {
                        final site = sites[index];
                        return AppCard(
                          onTap: () => context.push(AppRouter.siteForm, extra: site.id),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.teal.shade50,
                                child: Image.asset("assets/icons/location (1).png", color: Colors.teal, height: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      site.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (site.address.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        site.address,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Image.asset("assets/icons/trash (1).png", height: 20, color: Colors.redAccent),
                                onPressed: () => _deleteSite(site),
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
        onPressed: () => context.push(AppRouter.siteForm),
        tooltip: 'Add Site',
        child: const Icon(Icons.add),
      ),
    );
  }
}
