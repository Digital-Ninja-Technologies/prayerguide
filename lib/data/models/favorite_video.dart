class FavoriteVideo {
  const FavoriteVideo({required this.title, required this.url});

  final String title;
  final String url;

  factory FavoriteVideo.fromMap(Map<String, dynamic> map) => FavoriteVideo(
        title: map['video_title'] as String,
        url: map['video_url'] as String,
      );
}
