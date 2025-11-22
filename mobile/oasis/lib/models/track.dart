import 'package:isar/isar.dart';

part 'track.g.dart';

@collection
class Track {
  final Id id;
  final String title;
  final String artist;
  final String album;
  final String albumCover;
  final String releaseDate;
  final String genre;
  final int duration;
  String? localPath;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumCover,
    required this.releaseDate,
    required this.genre,
    required this.duration,
    this.localPath,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      albumCover: json['album_cover'] as String,
      releaseDate: json['release_date'] as String,
      genre: json['genre'] as String,
      duration: json['duration'] as int,
    );
  }

  String get formattedDuration {
    final duration = Duration(seconds: this.duration);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}