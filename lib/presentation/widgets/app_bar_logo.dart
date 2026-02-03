import 'package:flutter/material.dart';

class AppBarLogo extends StatelessWidget {
  const AppBarLogo({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop) {
      return _Logo(
        size: size,
        padding: const EdgeInsets.only(left: 12),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BackButton(),
        const SizedBox(width: 4),
        _Logo(size: size),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size, this.padding = EdgeInsets.zero});

  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: const AssetImage('assets/logo.jpg'),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
