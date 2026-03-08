import 'package:beltech/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class AssistantPromptGrid extends StatelessWidget {
  const AssistantPromptGrid({
    required this.prompts,
    required this.onPromptTap,
    super.key,
  });

  final List<String> prompts;
  final Future<void> Function(String) onPromptTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: prompts.map((prompt) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 60) / 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onPromptTap(prompt),
            child: GlassCard(
              borderRadius: 20,
              child: Text(
                prompt,
                style: TextStyle(color: onSurface),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
