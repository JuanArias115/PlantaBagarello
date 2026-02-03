import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
    required this.subtitle,
    this.title = 'Bagarello Cafe',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
