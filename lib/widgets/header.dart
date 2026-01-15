// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../core/theme.dart';

class Header extends StatelessWidget {
  final String title;
  final ThemeNotifier notifier;
  final VoidCallback? onNew;
  const Header({required this.notifier, this.title = 'Gensaku', this.onNew, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    String newLabel() {
      if (width < 360) return '+';
      if (width < 520) return 'New';
      return 'New Book';
    }

    return Material(
      elevation: 0,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Writer's icon - Book with pen
            Icon(
              Icons.auto_stories_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    'Your writing companion',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // New button
            FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(newLabel()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 8),
            // Theme selector
            ThemeButton(notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  final ThemeNotifier notifier;
  const ThemeButton({required this.notifier, super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // Toggle between light and dark
        notifier.setTheme(
          notifier.theme == AppTheme.light ? AppTheme.dark : AppTheme.light,
        );
      },
      icon: Icon(ThemeNotifier.iconFor(notifier.theme)),
      tooltip: notifier.theme == AppTheme.light ? 'Dark mode' : 'Light mode',
    );
  }
}
