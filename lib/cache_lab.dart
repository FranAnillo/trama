import 'package:flutter/material.dart';

class CacheLab extends StatefulWidget {
  const CacheLab({super.key});
  @override
  State<CacheLab> createState() => _CacheLabState();
}

class _CacheLabState extends State<CacheLab> {
  String? resident;
  String outcome = 'La línea está vacía.';
  void read(String block) => setState(() {
    outcome = resident == block
        ? 'Acierto. $block ya estaba en la línea.'
        : 'Fallo. Se trae $block y queda en la línea.';
    resident = block;
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laboratorio de memoria',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Semantics(liveRegion: true, child: Text(outcome)),
          Wrap(
            spacing: 8,
            children: [
              for (final b in ['A', 'B'])
                OutlinedButton(
                  onPressed: () => read(b),
                  child: Text('Leer $b'),
                ),
              TextButton(
                onPressed: () => setState(() {
                  resident = null;
                  outcome = 'La línea está vacía.';
                }),
                child: const Text('Vaciar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
