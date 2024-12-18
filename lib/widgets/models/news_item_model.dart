



// class NewsItemModel {
//   final String id;
//   final String name;
//   final String description;
//   final String banner;
//   late final String url;
//   late final String streamType;
//   final String genres;
//   final String status;
//   final String contentType; // Nayi property
//   bool isFocused;

//   NewsItemModel({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.banner,
//     required this.url,
//     required this.streamType,
//     required this.genres,
//     required this.status,
//     this.contentType = '', // Default value diya gaya hai
//     this.isFocused = false,
//   });

//   factory NewsItemModel.fromJson(Map<String, dynamic> json) {
//     return NewsItemModel(
//       id: json['id'].toString(),
//       name: json['name'] ?? '',
//       description: json['description'] ?? '',
//       banner: json['banner'] ?? '',
//       url: json['url'] ?? '',
//       streamType: json['stream_type'] ?? '',
//       genres: json['genres'] ?? '',
//       status: json['status'] ?? '',
//       contentType: json['content_type'] ?? '', // JSON se `contentType` ko fetch karna
//       isFocused: json['isFocused'] ?? false,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'description': description,
//       'banner': banner,
//       'url': url,
//       'stream_type': streamType,
//       'genres': genres,
//       'status': status,
//       'content_type': contentType, // `contentType` ko JSON mein add karna
//     };
//   }

//   /// Adds the `copyWith` method
//   NewsItemModel copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? banner,
//     String? url,
//     String? streamType,
//     String? genres,
//     String? status,
//     String? contentType, // `contentType` ko copyWith mein add kiya
//     bool? isFocused,
//   }) {
//     return NewsItemModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       banner: banner ?? this.banner,
//       url: url ?? this.url,
//       streamType: streamType ?? this.streamType,
//       genres: genres ?? this.genres,
//       status: status ?? this.status,
//       contentType: contentType ?? this.contentType,
//       isFocused: isFocused ?? this.isFocused,
//     );
//   }
// }



class NewsItemModel {
  final String id;
  final String name;
  final String description; // Optional in NewsItemModelone
  final String banner;
  final String url;
  final String streamType;
  final String genres;
  final String status;
  final String contentId; // Added from NewsItemModelone (renamed from content_id)
  final String contentType; // Optional, originally in NewsItemModel
  bool isFocused;
  final bool isYoutubeVideo;

  NewsItemModel({
    required this.id,
    required this.name,
    this.description = '', // Default value
    required this.banner,
    required this.url,
    required this.streamType,
    required this.genres,
    required this.status,
    this.contentId = '', // Default value for optional field
    this.contentType = '', // Default value for optional field
    this.isFocused = false,
    this.isYoutubeVideo = false,
  });

  /// Factory method for JSON deserialization
  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '', // Field from NewsItemModel
      banner: json['banner'] ?? '',
      url: json['url'] ?? '',
      streamType: json['stream_type'] ?? '',
      genres: json['genres'] ?? '',
      status: json['status'] ?? '',
      contentId: json['content_id'] ?? '', // Field from NewsItemModelone
      contentType: json['content_type'] ?? '', // Field from NewsItemModel
      isFocused: json['isFocused'] ?? false, // Field from NewsItemModel
      isYoutubeVideo: json['content_type'] == "1",
    );
  }

  /// Method for JSON serialization
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
      'content_id': contentId, // Field added from NewsItemModelone
      'content_type': contentType, // Field from NewsItemModel
      'isFocused': isFocused, // Field from NewsItemModel
      'isYoutubeVideo': isYoutubeVideo,

    };
  }

  /// Adds the `copyWith` method
  NewsItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? banner,
    String? url,
    String? streamType,
    String? genres,
    String? status,
    String? contentId,
    String? contentType,
    bool? isFocused,
    bool? isYoutubeVideo,
  }) {
    return NewsItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      banner: banner ?? this.banner,
      url: url ?? this.url,
      streamType: streamType ?? this.streamType,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      isFocused: isFocused ?? this.isFocused,
      isYoutubeVideo: isYoutubeVideo ?? this.isYoutubeVideo,
    );
  }
}
