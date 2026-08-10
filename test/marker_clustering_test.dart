import 'package:flutter_test/flutter_test.dart';
import 'package:conectenis_app/features/map/utils/marker_clustering.dart';

class _Point {
  const _Point(this.id, this.lat, this.lng);
  final String id;
  final double lat, lng;
}

List<MarkerCluster<_Point>> _cluster(List<_Point> points, {double thresholdMeters = 18}) {
  return clusterByProximity<_Point>(
    items: points,
    latOf: (p) => p.lat,
    lngOf: (p) => p.lng,
    idOf: (p) => p.id,
    thresholdMeters: thresholdMeters,
  );
}

void main() {
  group('clusterByProximity', () {
    test('far-apart points each form their own singleton cluster', () {
      final points = [
        const _Point('a', -23.1855, -46.886),
        const _Point('b', -23.20, -46.90), // several km away
      ];
      final clusters = _cluster(points);
      expect(clusters.length, 2);
      expect(clusters.every((c) => c.members.length == 1), isTrue);
    });

    test('near-identical points collapse into one cluster', () {
      final points = [
        const _Point('a', -23.1855, -46.886),
        const _Point('b', -23.18551, -46.88601), // ~1m away
      ];
      final clusters = _cluster(points);
      expect(clusters.length, 1);
      expect(clusters.first.members.length, 2);
    });

    test('cluster id is deterministic regardless of input order', () {
      final points = [
        const _Point('b', -23.1855, -46.886),
        const _Point('a', -23.18551, -46.88601),
      ];
      final reversed = points.reversed.toList();
      final id1 = _cluster(points).first.id;
      final id2 = _cluster(reversed).first.id;
      expect(id1, id2);
      expect(id1, 'a,b');
    });

    test('centroid is the arithmetic mean of member coordinates', () {
      final points = [
        const _Point('a', 0.0, 0.0),
        const _Point('b', 0.0001, 0.0001),
      ];
      final cluster = _cluster(points).first;
      expect(cluster.centroidLat, closeTo(0.00005, 1e-9));
      expect(cluster.centroidLng, closeTo(0.00005, 1e-9));
    });

    test('empty input produces no clusters', () {
      expect(_cluster(const []), isEmpty);
    });

    test('three points within threshold of a shared seed all join one cluster', () {
      final points = [
        const _Point('a', 0.0, 0.0),
        const _Point('b', 0.00005, 0.0), // ~5.5m from a
        const _Point('c', -0.00005, 0.0), // ~5.5m from a
      ];
      final clusters = _cluster(points, thresholdMeters: 10);
      expect(clusters.length, 1);
      expect(clusters.first.members.length, 3);
    });
  });

  group('spiderfyOffsets', () {
    test('a single-member group returns the centroid unchanged', () {
      final offsets = spiderfyOffsets(centroidLat: 10, centroidLng: 20, count: 1);
      expect(offsets, [(lat: 10.0, lng: 20.0)]);
    });

    test('multi-member groups fan out to distinct positions', () {
      final offsets = spiderfyOffsets(centroidLat: -23.18, centroidLng: -46.88, count: 4);
      expect(offsets.length, 4);
      final unique = offsets.map((o) => '${o.lat},${o.lng}').toSet();
      expect(unique.length, 4);
    });

    test('fanned-out positions stay close to the centroid', () {
      const centroidLat = -23.18;
      const centroidLng = -46.88;
      final offsets = spiderfyOffsets(
        centroidLat: centroidLat,
        centroidLng: centroidLng,
        count: 3,
        radiusMeters: 20,
      );
      for (final o in offsets) {
        expect((o.lat - centroidLat).abs(), lessThan(0.001));
        expect((o.lng - centroidLng).abs(), lessThan(0.001));
      }
    });
  });
}
