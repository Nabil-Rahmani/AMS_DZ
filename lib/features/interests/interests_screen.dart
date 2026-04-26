import 'package:flutter/material.dart';

class InterestsScreen extends StatelessWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interests'),
      ),
      body: const Center(
        child: Text('Interests Screen'),
      ),
    );
  }
}