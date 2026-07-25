import 'package:flutter/material.dart';

/// A colored rounded block showing a name.
/// The size follows the text: a short name is a small block, a longer name
/// makes it wider, and a name too long for one line wraps and makes it taller.
class NameTile extends StatelessWidget {
  final String name;
  final Color color;

  const NameTile({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        // No alignment here on purpose: a Container with an alignment expands to
        // the max incoming width, which would make every tile fill its own row.
        color: color,
        padding: const EdgeInsets.all(8),
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}
