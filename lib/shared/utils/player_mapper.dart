import 'package:conectenis_app/core/data/mock_data.dart';
import 'package:conectenis_app/shared/models/player.dart';
import 'package:conectenis_app/shared/models/user_profile.dart';

Player playerFromUserProfile(UserProfile user) {
  return Player(
    id: user.id,
    name: user.name,
    dateOfBirth: user.dateOfBirth,
    ntrpRating: user.ntrpRating,
    gender: user.gender,
    profession: user.profession,
    city: user.city,
    state: user.state,
    playStyle: user.playStyle,
    avatarUrl: user.avatarUrl,
    latitude: user.latitude ?? MockData.centerLat,
    longitude: user.longitude ?? MockData.centerLng,
  );
}
