class NewsItemModel {
  final String id;
  final String name;
  final String description;
  final String banner;
  final String url;
  final String streamType;
  final String genres;
  final String status;

  NewsItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.banner,
    required this.url,
    required this.streamType,
    required this.genres,
    required this.status,
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      banner: json['banner'] ?? '',
      url: json['url'] ?? '',
      streamType: json['stream_type'] ?? '',
      genres: json['genres'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'banner': banner,
      'url': url,
      'stream_type': streamType,
      'genres': genres,
      'status': status,
    };
  }
}