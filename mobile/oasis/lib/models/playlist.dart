import 'package:isar/isar.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  final Id id;
  String name;
  String coverImage;
  List<int> trackIds;

  Playlist({
    required this.id,
    required this.name,
    required this.coverImage,
    required this.trackIds,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String,
      coverImage: json['cover_image'] as String,
      trackIds: (json['tracks'] as List).map((t) => t['id'] as int).toList(),
    );
  }
}
