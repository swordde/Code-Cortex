import 'package:flutter/material.dart';

class CustomModeScreen extends StatelessWidget {
  const CustomModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Mode')),
      body: const Center(child: Text('Screen 4 placeholder')),
    );
  }
}
