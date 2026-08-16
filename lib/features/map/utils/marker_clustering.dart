import 'dart:math' as math;

import 'package:conectenis_app/shared/utils/geo.dart';

/// A group of one or more items sitting at (near-)identical map
/// coordinates. Size-1 clusters render exactly like a normal marker; larger
/// ones collapse into a single "N here" marker that spiderfies on tap.
class MarkerCluster<T> {
  const MarkerCluster({
    required this.id,
    required this.members,
    required this.centroidLat,
    required this.centroidLng,
  });

  /// Deterministic (sorted member ids, joined) so it keeps matching the
  /// same real-world group across rebuilds of the same underlying list -
  /// this is what lets "which cluster is currently expanded" state survive
  /// a `_rebuildMarkers()` call.
  final String id;
  final List<T> members;
  final double centroidLat;
  final double centroidLng;
}

/// Greedy proximity grouping: items within [thresholdMeters] of each other
/// collapse into one [MarkerCluster]. O(n²), which is fine at the scale of
/// one map viewport (tens of markers, not thousands).
List<MarkerCluster<T>> clusterByProximity<T>({
  required List<T> items,
  required double Function(T) latOf,
  required double Function(T) lngOf,
  required String Function(T) idOf,
  double thresholdMeters = 18,
}) {
  final remaining = List<T>.from(items);
  final clusters = <MarkerCluster<T>>[];

  while (remaining.isNotEmpty) {
    final seed = remaining.removeAt(0);
    final group = <T>[seed];
    remaining.removeWhere((candidate) {
      final distanceMeters =
          distanceKmBetween(latOf(seed), lngOf(seed), latOf(candidate), lngOf(candidate)) *
              1000;
      if (distanceMeters <= thresholdMeters) {
        group.add(candidate);
        return true;
      }
      return false;
    });

    final ids = group.map(idOf).toList()..sort();
    final centroidLat = group.map(latOf).reduce((a, b) => a + b) / group.length;
    final centroidLng = group.map(lngOf).reduce((a, b) => a + b) / group.length;

    clusters.add(MarkerCluster<T>(
      id: ids.join(','),
      members: group,
      centroidLat: centroidLat,
      centroidLng: centroidLng,
    ));
  }

  return clusters;
}

/// Ground distance (meters) covered by one screen pixel at [zoom], using
/// the standard Web Mercator ground-resolution formula Google Maps' zoom
/// levels are defined against. Lets us size the spiderfy fan in *screen*
/// space (so it always reads clearly, at any zoom) while still working
/// with the lat/lng offsets the Maps SDK needs.
double metersPerPixel(double latitude, double zoom) {
  final latRad = latitude * math.pi / 180;
  return 156543.03392 * math.cos(latRad).abs() / math.pow(2, zoom);
}

/// Pixel radius to fan [count] members out to so neighboring markers land
/// roughly [spacing] px apart on the circle (chord length = spacing).
/// Clamped so a 2-member cluster doesn't collapse to nothing and a huge
/// one doesn't fan off-screen.
double spiderfyPixelRadius(int count, {double spacing = 58}) {
  if (count <= 1) return 0;
  final raw = spacing / (2 * math.sin(math.pi / count));
  return raw.clamp(46.0, 140.0);
}

/// Fan-out offset positions for spiderfying an expanded cluster - evenly
/// spaced around the centroid at [radiusMeters], using the standard
/// small-distance lat/lng approximation (fine at this scale, no new
/// dependency needed).
List<({double lat, double lng})> spiderfyOffsets({
  required double centroidLat,
  required double centroidLng,
  required int count,
  double radiusMeters = 35,
}) {
  if (count <= 1) return [(lat: centroidLat, lng: centroidLng)];

  const metersPerDegreeLat = 111320.0;
  final latCosFactor =
      math.cos(centroidLat * math.pi / 180).abs().clamp(0.2, 1.0);
  final metersPerDegreeLng = metersPerDegreeLat * latCosFactor;

  return List.generate(count, (i) {
    final angle = (2 * math.pi * i) / count;
    final dLat = (radiusMeters * math.cos(angle)) / metersPerDegreeLat;
    final dLng = (radiusMeters * math.sin(angle)) / metersPerDegreeLng;
    return (lat: centroidLat + dLat, lng: centroidLng + dLng);
  });
}
