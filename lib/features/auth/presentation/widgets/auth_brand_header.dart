import 'package:beltech/core/widgets/beltech_logo.dart';
import 'package:flutter/material.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BeltechLogo(),
        const SizedBox(height: 14),
        Text(
          'BELTECH',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Innovate and Create',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
