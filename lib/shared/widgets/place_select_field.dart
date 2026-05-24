import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/shared/models/place.dart';

class PlaceSelectField extends StatelessWidget {
  const PlaceSelectField({
    super.key,
    required this.selectedPlace,
    required this.onChanged,
    this.label = 'Local',
  });

  final Place? selectedPlace;
  final ValueChanged<Place?> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final place = await context.push<Place>('/places-search?select=true');
    if (place != null) onChanged(place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.search),
          label: Text(selectedPlace == null ? 'Buscar local' : 'Trocar local'),
        ),
        if (selectedPlace != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.place),
              title: Text(selectedPlace!.name),
              subtitle: Text(selectedPlace!.subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onChanged(null),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
