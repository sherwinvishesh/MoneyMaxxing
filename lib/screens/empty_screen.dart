// lib/screens/empty_screen.dart
import 'package:flutter/material.dart';

class EmptyScreen extends StatelessWidget {
  final String title;

  const EmptyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 24,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
