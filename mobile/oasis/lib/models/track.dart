class Track {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String albumCover;
  final String releaseDate;
  final String genre;
  final int duration;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumCover,
    required this.releaseDate,
    required this.genre,
    required this.duration,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      albumCover: json['album_cover'],
      releaseDate: json['release_date'],
      genre: json['genre'],
      duration: json['duration'],
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