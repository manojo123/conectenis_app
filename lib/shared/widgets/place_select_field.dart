import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:conectenis_app/shared/models/nearby_court.dart';

class PlaceSelectField extends StatelessWidget {
  const PlaceSelectField({
    super.key,
    required this.selectedCourt,
    required this.onChanged,
    this.label = 'Local',
  });

  final NearbyCourt? selectedCourt;
  final ValueChanged<NearbyCourt?> onChanged;
  final String label;

  Future<void> _pick(BuildContext context) async {
    final court = await context.push<NearbyCourt>('/courts-picker?select=true');
    if (court != null) onChanged(court);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pick(context),
          icon: const Icon(Icons.place),
          label: Text(selectedCourt == null ? 'Escolher quadra por perto' : 'Trocar quadra'),
        ),
        if (selectedCourt != null) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                selectedCourt!.isGooglePlace ? Icons.map : Icons.place,
              ),
              title: Text(selectedCourt!.name),
              subtitle: Text(selectedCourt!.subtitle),
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
