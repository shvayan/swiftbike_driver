import 'package:flutter/material.dart';

import '../controller/counter_controller.dart';

class CounterView extends StatelessWidget {
  const CounterView({super.key, required this.controller});

  final CounterController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SwiftBike Driver MVC'),
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Current count'),
                const SizedBox(height: 12),
                Text(
                  '${controller.count}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: controller.increment,
                  icon: const Icon(Icons.add),
                  label: const Text('Increment'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
