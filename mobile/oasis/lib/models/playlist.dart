import 'package:isar/isar.dart';

part 'playlist.g.dart';

@collection
class Playlist {
  Id id = Isar.autoIncrement;

  @Index()
  int? remoteId;

  String name;
  String coverImage;
  List<int> trackIds;

  bool isDeleted;

  Playlist({
    this.id = Isar.autoIncrement,
    this.remoteId,
    required this.name,
    required this.coverImage,
    required this.trackIds,
    this.isDeleted = false,
  });

  bool get isSynced => remoteId != null;
}