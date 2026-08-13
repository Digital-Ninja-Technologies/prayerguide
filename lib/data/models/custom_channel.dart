class CustomChannel {
  const CustomChannel(
      {required this.id, required this.name, required this.url});

  final String id;
  final String name;
  final String url;

  factory CustomChannel.fromMap(Map<String, dynamic> map) => CustomChannel(
        id: map['id'] as String,
        name: map['channel_name'] as String,
        url: map['channel_url'] as String,
      );
}
