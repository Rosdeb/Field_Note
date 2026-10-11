import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/site_bloc.dart';
import '../bloc/site_form_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/widgets.dart';
import '../../../routes/app_router.dart';

class SiteFormScreen extends StatelessWidget {
  final String? siteId;
  const SiteFormScreen({super.key, this.siteId});

  @override
  Widget build(BuildContext context) {
    final services = ServiceLocator();
    return BlocProvider(
      create: (_) => SiteFormBloc(
        customerRepository: services.customerRepository,
        siteRepository: services.siteRepository,
      )..add(LoadSiteForm(siteId: siteId)),
      child: _SiteFormView(siteId: siteId),
    );
  }
}

class _SiteFormView extends StatefulWidget {
  final String? siteId;
  const _SiteFormView({this.siteId});
  @override
  State<_SiteFormView> createState() => _SiteFormViewState();
}

class _SiteFormViewState extends State<_SiteFormView> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomer() async {
    FocusScope.of(context).unfocus();
    final bloc = context.read<SiteFormBloc>();
    bloc.add(const SearchSiteCustomers(''));
    final customerId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _CustomerPicker()),
    );
    if (mounted && customerId != null) bloc.add(SelectSiteCustomer(customerId));
  }

  Future<void> _addCustomer() async {
    await context.push(AppRouter.customerForm);
    if (mounted) {
      context.read<SiteFormBloc>().add(LoadSiteForm(siteId: widget.siteId));
    }
  }

  void _save() {
    context.read<SiteFormBloc>().add(
      SubmitSiteForm(
        name: _nameController.text,
        address: _addressController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.siteId != null;
    final theme = Theme.of(context);
    return BlocConsumer<SiteFormBloc, SiteFormState>(
      listener: (context, state) {
        if (!state.isLoading && !_controllersInitialized) {
          _controllersInitialized = true;
          _nameController.text = state.existingSite?.name ?? '';
          _addressController.text = state.existingSite?.address ?? '';
        }
        if (state.error != null) {
          FloatingErrorBar.show(context, message: state.error!);
        }
        if (state.isSaved) {
          context.read<SiteBloc>().add(const LoadSites());
          context.pop();
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Site' : 'Add Site')),
        body: state.isLoading
            ? const LoadingView(message: 'Loading site details...')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Customer *', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Semantics(
                      button: true,
                      label: 'Choose customer',
                      child: InkWell(
                        onTap: state.customers.isEmpty || state.isSaving
                            ? null
                            : _selectCustomer,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.selectedCustomer?.name ?? 'Select a customer',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: state.selectedCustomer == null
                                                ? theme.colorScheme.onSurfaceVariant
                                                : theme.colorScheme.onSurface,
                                          ),
                                    ),
                                    if (state.selectedCustomer?.contactInformation.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        state.selectedCustomer!.contactInformation,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.customers.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Add a customer before creating a site.'),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addCustomer,
                          icon: const Icon(Icons.add),
                          label: const Text('Add customer'),
                        ),
                      ),
                    ] else if (isEditing &&
                        state.existingSite != null &&
                        state.customerId == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The previous customer is unavailable. Select another customer.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _nameController,
                      title: 'Site name *',
                      hint: 'Building A, North Wing',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _addressController,
                      title: 'Address',
                      hint: 'Street, area, city',
                      prefixIcon: const Icon(Icons.pin_drop_outlined),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 28),
                    AppButton(
                      text: isEditing ? 'Update Site' : 'Save Site',
                      icon: Icons.check,
                      isLoading: state.isSaving,
                      onPressed: state.customers.isEmpty ? null : _save,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SiteFormBloc>().add(const SearchSiteCustomers(''));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select a customer',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SiteFormBloc, SiteFormState>(
                    buildWhen: (previous, current) => previous.query != current.query,
                    builder: (context, state) => TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(

                        hintText: 'Search by name or contact',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: _clearSearch,
                                icon: const Icon(Icons.close),
                              ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHigh,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (query) => context.read<SiteFormBloc>().add(
                        SearchSiteCustomers(query),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SiteFormBloc, SiteFormState>(
                builder: (context, state) {
                  final customers = state.filteredCustomers;
                  if (customers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'No customers match your search.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _clearSearch,
                              child: const Text('Clear search'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final selected = customer.id == state.customerId;
                      return ListTile(
                        title: Text(
                          customer.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.green.withValues(alpha: 0.2),
                          ),
                          child: Icon(Icons.person),
                        ),
                        subtitle: customer.contactInformation.isEmpty
                            ? null
                            : Text(
                                customer.contactInformation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        selected: selected,
                        selectedTileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        trailing: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        onTap: () => Navigator.of(context).pop(customer.id),
                      );
                    },
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
