import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../models/customer.dart';
import '../../../models/site.dart';
import '../bloc/field_note_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/widgets.dart';
import '../bloc/field_note_form_bloc.dart';

class FieldNoteFormScreen extends StatelessWidget {
  final String? noteId;

  const FieldNoteFormScreen({super.key, this.noteId});

  @override
  Widget build(BuildContext context) {
    final services = ServiceLocator();
    return BlocProvider(
      create: (_) => FieldNoteFormBloc(
        customerRepository: services.customerRepository,
        siteRepository: services.siteRepository,
        fieldNoteRepository: services.fieldNoteRepository,
      )..add(LoadFieldNoteForm(noteId: noteId)),
      child: _FieldNoteFormView(noteId: noteId),
    );
  }
}

class _FieldNoteFormView extends StatefulWidget {
  final String? noteId;
  const _FieldNoteFormView({this.noteId});

  @override
  State<_FieldNoteFormView> createState() => _FieldNoteFormViewState();
}

class _FieldNoteFormViewState extends State<_FieldNoteFormView> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    context.read<FieldNoteFormBloc>().add(
      SubmitFieldNoteForm(
        title: _titleController.text,
        notes: _notesController.text,
      ),
    );
  }

  Future<void> _selectCustomer(
    BuildContext context,
    FieldNoteFormState state,
  ) async {
    final bloc = context.read<FieldNoteFormBloc>();
    final customerId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _CustomerPickerSheet(
        customers: state.customers,
        selectedCustomerId: state.customerId,
      ),
    );
    if (mounted && customerId != null) {
      bloc.add(SelectNoteCustomer(customerId));
    }
  }

  Future<void> _selectSite(
    BuildContext context,
    FieldNoteFormState state,
  ) async {
    final bloc = context.read<FieldNoteFormBloc>();
    final siteId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SitePickerSheet(
        sites: state.sites,
        selectedSiteId: state.siteId,
      ),
    );
    if (mounted && siteId != null) {
      bloc.add(SelectNoteSite(siteId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;
    final theme = Theme.of(context);

    return BlocConsumer<FieldNoteFormBloc, FieldNoteFormState>(
      listener: (context, state) {
        if (!state.isLoading && !_controllersInitialized) {
          _controllersInitialized = true;
          _titleController.text = state.existingNote?.title ?? '';
          _notesController.text = state.existingNote?.notes ?? '';
        }
        if (state.error != null) {
          FloatingErrorBar.show(context, message: state.error!);
        }
        if (state.isSaved) {
          context.read<FieldNoteBloc>().add(const LoadFieldNotes());
          context.pop();
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Field Note' : 'New Field Note'),
        ),
        body: state.isLoading
            ? const LoadingView(message: 'Loading note details...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.customers.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              final selectedCustomer = state.customers
                                  .where((c) => c.id == state.customerId)
                                  .firstOrNull;

                              return Semantics(
                                button: true,
                                label: 'Select customer',
                                child: InkWell(
                                  onTap: state.isSaving
                                      ? null
                                      : () => _selectCustomer(context, state),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: Text((selectedCustomer?.name.isNotEmpty ?? false)
                                                ? selectedCustomer!.name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                selectedCustomer?.name ?? 'Select a customer',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: selectedCustomer == null
                                                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                                      : theme.colorScheme.onSurface,
                                                ),
                                              ),
                                              if (selectedCustomer?.contactInformation.isNotEmpty ?? false) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  selectedCustomer!.contactInformation,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.sites.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Site',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Builder(
                            builder: (context) {
                              final selectedSite = state.sites.where((s) => s.id == state.siteId).firstOrNull;

                              return Semantics(
                                button: true,
                                label: 'Select site',
                                child: InkWell(
                                  onTap: state.isSaving
                                      ? null
                                      : () => _selectSite(context, state),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7,),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: theme.colorScheme.secondaryContainer,
                                          child: Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: theme.colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                selectedSite?.name ?? 'Select a site',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  color: selectedSite == null
                                                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                                      : theme.colorScheme.onSurface,
                                                ),
                                              ),
                                              if (selectedSite?.address.isNotEmpty ?? false) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  selectedSite!.address,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    AppTextField(
                      controller: _titleController,
                      title: 'Title / Subject *',
                      hint: 'e.g. Foundation crack inspection',
                      prefixIcon: const Icon(Icons.title),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _notesController,
                      title: 'Observations & Details',
                      hint: 'Describe findings, measurements, conditions...',
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          key: ValueKey('status-${state.status}'),
                          initialValue: state.status,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          items: [
                            if (![
                              'DRAFT',
                              'OPEN',
                              'IN_PROGRESS',
                              'COMPLETED',
                            ].contains(state.status))
                              DropdownMenuItem(
                                value: state.status,
                                child: Text(
                                  state.status.isEmpty
                                      ? 'Unknown status'
                                      : state.status,
                                ),
                              ),
                            const DropdownMenuItem(
                              value: 'DRAFT',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note, size: 18, color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Text('Draft'),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: 'OPEN',
                              child: Row(
                                children: [
                                  Icon(Icons.radio_button_checked, size: 18, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Open'),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: 'IN_PROGRESS',
                              child: Row(
                                children: [
                                  Icon(Icons.pending_outlined, size: 18, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('In Progress'),
                                ],
                              ),
                            ),
                            const DropdownMenuItem(
                              value: 'COMPLETED',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Completed'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              context.read<FieldNoteFormBloc>().add(
                                SelectNoteStatus(val),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Attach Inspection Photos',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: isEditing ? 'Update Note' : 'Save Field Note',
                      icon: Icons.save_outlined,
                      isLoading: state.isSaving,
                      onPressed: _handleSave,
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;
  final String? selectedCustomerId;

  const _CustomerPickerSheet({
    required this.customers,
    required this.selectedCustomerId,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchQuery.trim().toLowerCase();

    final filteredCustomers = query.isEmpty
        ? widget.customers
        : widget.customers.where((customer) {
            final nameMatch = customer.name.toLowerCase().contains(query);
            final contactMatch = customer.contactInformation
                .toLowerCase()
                .contains(query);
            return nameMatch || contactMatch;
          }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Customer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or contact...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No customers found',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No customers match "$_searchQuery"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final isSelected =
                            customer.id == widget.selectedCustomerId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primaryContainer,
                            foregroundColor: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onPrimaryContainer,
                            child: Text(
                              customer.name.isNotEmpty
                                  ? customer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: customer.contactInformation.isNotEmpty
                              ? Text(
                                  customer.contactInformation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(customer.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SitePickerSheet extends StatefulWidget {
  final List<Site> sites;
  final String? selectedSiteId;

  const _SitePickerSheet({
    required this.sites,
    required this.selectedSiteId,
  });

  @override
  State<_SitePickerSheet> createState() => _SitePickerSheetState();
}

class _SitePickerSheetState extends State<_SitePickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchQuery.trim().toLowerCase();

    final filteredSites = query.isEmpty
        ? widget.sites
        : widget.sites.where((site) {
            final nameMatch = site.name.toLowerCase().contains(query);
            final addressMatch = site.address.toLowerCase().contains(query);
            return nameMatch || addressMatch;
          }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Site',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by site name or address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredSites.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sites found',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No sites match "$_searchQuery"',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredSites.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        indent: 68,
                        endIndent: 16,
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final site = filteredSites[index];
                        final isSelected = site.id == widget.selectedSiteId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.secondaryContainer,
                            foregroundColor: isSelected
                                ? theme.colorScheme.onSecondary
                                : theme.colorScheme.onSecondaryContainer,
                            child: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            site.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: site.address.isNotEmpty
                              ? Text(
                                  site.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.secondary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(site.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
