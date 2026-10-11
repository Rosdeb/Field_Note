abstract class SiteFormEvent {
  const SiteFormEvent();
}

class LoadSiteForm extends SiteFormEvent {
  final String? siteId;
  const LoadSiteForm({this.siteId});
}

class SelectSiteCustomer extends SiteFormEvent {
  final String customerId;
  const SelectSiteCustomer(this.customerId);
}

class SearchSiteCustomers extends SiteFormEvent {
  final String query;
  const SearchSiteCustomers(this.query);
}

class SubmitSiteForm extends SiteFormEvent {
  final String name;
  final String address;
  const SubmitSiteForm({required this.name, required this.address});
}
