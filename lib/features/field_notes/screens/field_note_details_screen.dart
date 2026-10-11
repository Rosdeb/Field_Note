import 'package:flutter/material.dart';

class FieldNoteDetailsScreen extends StatelessWidget {
  final String noteId;

  const FieldNoteDetailsScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field Note Details')),
      body: Center(
        child: Text('Details for field note: $noteId'),
      ),
    );
  }
}
