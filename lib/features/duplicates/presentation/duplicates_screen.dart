import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'duplicates_providers.dart';
import 'merge_screen.dart';

/// Lista mozliwych duplikatow (sprzet wspoldzielacy ten sam numer seryjny) -
/// glowne narzedzie do faktycznego posprzatania balaganu w istniejacych
/// danych, nie tylko zapobiegania nowym duplikatom.
class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(duplicateGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mozliwe duplikaty')),
      body: groups.isEmpty
          ? const Center(
              child: Text('Brak wykrytych duplikatow (po numerze seryjnym).'),
            )
          : ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final serial = group.first.serialNumber ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ),
                    title: Text('S/N: $serial'),
                    subtitle: Text(
                      '${group.map((a) => a.name).join(' / ')} • ${group.length} rekordy',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MergeScreen(assetA: group[0], assetB: group[1]),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
