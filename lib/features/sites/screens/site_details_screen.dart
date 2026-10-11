import 'package:flutter/material.dart';

class SiteDetailsScreen extends StatelessWidget {
  final String siteId;

  const SiteDetailsScreen({super.key, required this.siteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Details')),
      body: Center(
        child: Text('Details for site: $siteId'),
      ),
    );
  }
}
