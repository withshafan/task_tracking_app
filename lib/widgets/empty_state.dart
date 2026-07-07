import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onActionPressed,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withAlpha(130),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.08, 1.08),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha(150),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
