class FavoriteChannel {
  const FavoriteChannel({required this.name, required this.url});

  final String name;
  final String url;

  factory FavoriteChannel.fromMap(Map<String, dynamic> map) => FavoriteChannel(
        name: map['channel_name'] as String,
        url: map['channel_url'] as String,
      );
}
