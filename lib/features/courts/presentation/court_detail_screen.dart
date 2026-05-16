import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:conectenis_app/features/courts/data/courts_repository.dart';
import 'package:conectenis_app/shared/widgets/error_view.dart';
import 'package:conectenis_app/shared/widgets/loading_view.dart';

class CourtDetailScreen extends ConsumerWidget {
  const CourtDetailScreen({super.key, required this.courtId});

  final int courtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(courtsRepositoryProvider).byId(courtId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingView());
        }
        final court = snapshot.data;
        if (court == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ErrorView(message: 'Quadra não encontrada'),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(court.name)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.sports_tennis, size: 64),
              const SizedBox(height: 16),
              Text(court.address, style: Theme.of(context).textTheme.bodyLarge),
              if (court.city != null) Text('${court.city} - ${court.state ?? 'SP'}'),
              const SizedBox(height: 24),
              if (court.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(court.phone!),
                  onTap: () => launchUrl(Uri.parse('tel:${court.phone}')),
                ),
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Abrir no Google Maps'),
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${court.latitude},${court.longitude}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
