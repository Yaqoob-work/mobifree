



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



// class NewsItemModel {
//   final String id;
//   final String name;
//   final String description; // Optional in NewsItemModelone
//   final String banner;
//   final String url;
//   final String streamType;
//   final String genres;
//   final String status;
//   final String contentId; // Added from NewsItemModelone (renamed from content_id)
//   final String contentType; // Optional, originally in NewsItemModel
//   bool isFocused;
//   final bool isYoutubeVideo;
  

//   NewsItemModel({
//     required this.id,
//     required this.name,
//     this.description = '', // Default value
//     required this.banner,
//     required this.url,
//     required this.streamType,
//     required this.genres,
//     required this.status,
//     this.contentId = '', // Default value for optional field
//     this.contentType = '', // Default value for optional field
//     this.isFocused = false,
//     this.isYoutubeVideo = false,
//   });

//   /// Factory method for JSON deserialization
//   factory NewsItemModel.fromJson(Map<String, dynamic> json) {
//     return NewsItemModel(
//       id: json['id']?.toString() ?? '',
//       name: json['name'] ?? '',
//       description: json['description'] ?? '', // Field from NewsItemModel
//       banner: json['banner'] ?? '',
//       url: json['url'] ?? '',
//       streamType: json['stream_type'] ?? '',
//       genres: json['genres'] ?? '',
//       status: json['status'] ?? '',
//       contentId: json['content_id'] ?? '', // Field from NewsItemModelone
//       contentType: json['content_type'] ?? '', // Field from NewsItemModel
//       isFocused: json['isFocused'] ?? false, // Field from NewsItemModel
//       isYoutubeVideo: json['content_type'] == "1",
//     );
//   }

//   /// Method for JSON serialization
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
//       'content_id': contentId, // Field added from NewsItemModelone
//       'content_type': contentType, // Field from NewsItemModel
//       'isFocused': isFocused, // Field from NewsItemModel
//       'isYoutubeVideo': isYoutubeVideo,

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
//     String? contentId,
//     String? contentType,
//     bool? isFocused,
//     bool? isYoutubeVideo,
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
//       contentId: contentId ?? this.contentId,
//       contentType: contentType ?? this.contentType,
//       isFocused: isFocused ?? this.isFocused,
//       isYoutubeVideo: isYoutubeVideo ?? this.isYoutubeVideo,
//     );
//   }
// }



class NewsItemModel {
  final String id;
  final String index;
  final String name;
  final String description; // Optional in NewsItemModel
  final String thumbnail; // Optional in NewsItemModel
  final String banner;
  final String url;
  final String videoId;
  final String streamType;
  final String type;
  final String genres;
  final String status;
  final String contentId; // Added from NewsItemModelone (renamed from content_id)
  final String contentType; // Optional, originally in NewsItemModel
  bool isFocused;
  final bool isYoutubeVideo;
  final Duration position;
  bool liveStatus; // New field for position

  NewsItemModel({
    required this.id,
    required this.index,
    required this.name,
    this.description = '', // Default value
    this.thumbnail = '', // Default value
    required this.banner,
    required this.url,
     required this.videoId,
    required this.streamType,
    required this.type,
    required this.genres,
    required this.status,
    this.contentId = '', // Default value for optional field
    this.contentType = '', // Default value for optional field
    this.isFocused = false,
    this.isYoutubeVideo = false,
    this.position = Duration.zero, 
    this.liveStatus = false, // Default value for new field
  });

  /// Factory method for JSON deserialization
  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: json['id']?.toString() ?? '',
      index: json['index']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '', // Field from NewsItemModel
      thumbnail: json['thumbnail'] ?? '', // Field from NewsItemModel
      banner: json['banner'] ?? '',
      url: json['url'] ?? '',
      videoId: json['videoId'] ?? '',
      streamType: json['stream_type'] ?? '',
      type: json['type'] ?? '',
      genres: json['genres'] ?? '',
      status: json['status'] ?? '',
      contentId: json['content_id'] ?? '', // Field from NewsItemModelone
      contentType: json['content_type'] ?? '', // Field from NewsItemModel
      isFocused: json['isFocused'] ?? false, // Field from NewsItemModel
      liveStatus: json['liveStatus'] ?? false, // Field from NewsItemModel
      isYoutubeVideo: json['content_type'] == "1",
      position: Duration(milliseconds: json['position'] ?? 0), // Parse position as Duration
    );
  }

  /// Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'name': name,
      'description': description,
      'thumbnail': thumbnail,
      'banner': banner,
      'url': url,
      'videoId': videoId,
      'stream_type': streamType,
      'type': type,
      'genres': genres,
      'status': status,
      'content_id': contentId, // Field added from NewsItemModelone
      'content_type': contentType, // Field from NewsItemModel
      'isFocused': isFocused, // Field from NewsItemModel
      'liveStatus': liveStatus, // Field from NewsItemModel
      'isYoutubeVideo': isYoutubeVideo,
      'position': position.inMilliseconds, // Convert position to milliseconds
    };
  }

  /// Adds the `copyWith` method
  NewsItemModel copyWith({
    String? id,
    String? index,
    String? name,
    String? description,
    String? thumbnail,
    String? banner,
    String? url,
    String? videoId,
    String? streamType,
    String? type,
    String? genres,
    String? status,
    String? contentId,
    String? contentType,
    bool? isFocused,
    bool? liveStatus,
    bool? isYoutubeVideo,
    Duration? position, // Include new field
  }) {
    return NewsItemModel(
      id: id ?? this.id,
      index: id ?? this.index,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnail: thumbnail ?? this.thumbnail,
      banner: banner ?? this.banner,
      url: url ?? this.url,
      videoId: url ?? this.videoId,
      streamType: streamType ?? this.streamType,
      type: streamType ?? this.type,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      isFocused: isFocused ?? this.isFocused,
      liveStatus: liveStatus ?? this.liveStatus,
      isYoutubeVideo: isYoutubeVideo ?? this.isYoutubeVideo,
      position: position ?? this.position, // Copy or default to the current value
    );
  }
}
