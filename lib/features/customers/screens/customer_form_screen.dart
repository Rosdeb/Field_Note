import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/customer_bloc.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/customer.dart';

class CustomerFormScreen extends StatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  Customer? _existingCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final customer = await ServiceLocator().customerRepository.getCustomerById(widget.customerId!);
    if (mounted && customer != null) {
      _existingCustomer = customer;
      _nameController.text = customer.name;
      _contactController.text = customer.contactPerson;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
      _addressController.text = customer.address;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return;
    }

    final customer = Customer(
      id: widget.customerId ?? '',
      name: name,
      contactPerson: _contactController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      version: _existingCustomer?.version ?? 0,
    );

    context.read<CustomerBloc>().add(SaveCustomerEvent(customer: customer));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'Add Customer')),
      body: _isLoading
          ? const LoadingView(message: 'Loading customer details...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameController,
                    title: 'Customer / Company Name *',
                    hint: 'e.g. Acme Corporation',
                    prefixIcon: const Icon(Icons.business_outlined),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _contactController,
                    title: 'Contact Person',
                    hint: 'e.g. Jane Smith',
                    prefixIcon: const Icon(Icons.person_outline),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _phoneController,
                    title: 'Phone Number',
                    hint: 'e.g. +1 555-0199',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    title: 'Email Address',
                    hint: 'e.g. contact@acme.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _addressController,
                    title: 'Address',
                    hint: 'e.g. 100 Industrial Parkway',
                    prefixIcon: const Icon(Icons.location_city_outlined),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: isEditing ? 'Update Customer' : 'Save Customer',
                    icon: Icons.check,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
    );
  }
}
