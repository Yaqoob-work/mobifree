



// class NewsItemModel {
//   final String id;
//   final String index;
//   final String name;
//   final String description; // Optional in NewsItemModel
//   final String thumbnail; // Optional in NewsItemModel
//   final String banner;
//   final String poster;
//   final String url;
//   final String videoId;
//   final String streamType;
//   final String type;
//   final String genres;
//   final String status;
//   final String category;
//   final String contentId; // Added from NewsItemModelone (renamed from content_id)
//   final String contentType; // Optional, originally in NewsItemModel
//   bool isFocused;
//   final bool isYoutubeVideo;
//   final Duration position;
//   bool liveStatus; // New field for position

//   NewsItemModel({
//     required this.id,
//     required this.index,
//     required this.name,
//     this.description = '', // Default value
//     this.thumbnail = '', // Default value
//     required this.banner,
//     required this.poster,
//     required this.url,
//      required this.videoId,
//     required this.streamType,
//     required this.type,
//     required this.genres,
//     required this.status,
//     this.contentId = '', // Default value for optional field
//     this.contentType = '', // Default value for optional field
//     this.isFocused = false,
//     this.isYoutubeVideo = false,
//     this.position = Duration.zero, 
//     this.liveStatus = false, 
//     required this.category, // Default value for new field
//   });

//   /// Factory method for JSON deserialization
//   factory NewsItemModel.fromJson(Map<String, dynamic> json) {
//     return NewsItemModel(
//       id: json['id']?.toString() ?? '',
//       index: json['index']?.toString() ?? '',
//       name: json['name'] ?? '',
//       description: json['description'] ?? '', // Field from NewsItemModel
//       thumbnail: json['thumbnail'] ?? '', // Field from NewsItemModel
//       banner: json['banner'] ?? '',
//       poster: json['poster'] ?? '',
//       category: json['category'] ?? '',
//       url: json['url'] ?? '',
//       videoId: json['videoId'] ?? '',
//       streamType: json['stream_type'] ?? '',
//       type: json['type'] ?? '',
//       genres: json['genres'] ?? '',
//       status: json['status'] ?? '',
//       contentId: json['content_id'] ?? '', // Field from NewsItemModelone
//       contentType: json['content_type'] ?? '', // Field from NewsItemModel
//       isFocused: json['isFocused'] ?? false, // Field from NewsItemModel
//       liveStatus: json['liveStatus'] ?? false, // Field from NewsItemModel
//       isYoutubeVideo: json['content_type'] == "1",
//       position: Duration(milliseconds: json['position'] ?? 0), // Parse position as Duration
//     );
//   }

//   /// Method for JSON serialization
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'index': index,
//       'name': name,
//       'description': description,
//       'thumbnail': thumbnail,
//       'banner': banner,
//       'poster': poster,
//       'category': category,
//       'url': url,
//       'videoId': videoId,
//       'stream_type': streamType,
//       'type': type,
//       'genres': genres,
//       'status': status,
//       'content_id': contentId, // Field added from NewsItemModelone
//       'content_type': contentType, // Field from NewsItemModel
//       'isFocused': isFocused, // Field from NewsItemModel
//       'liveStatus': liveStatus, // Field from NewsItemModel
//       'isYoutubeVideo': isYoutubeVideo,
//       'position': position.inMilliseconds, // Convert position to milliseconds
//     };
//   }

//   /// Adds the `copyWith` method
//   NewsItemModel copyWith({
//     String? id,
//     String? index,
//     String? name,
//     String? description,
//     String? thumbnail,
//     String? banner,
//     String? poster,
//     String? category,
//     String? url,
//     String? videoId,
//     String? streamType,
//     String? type,
//     String? genres,
//     String? status,
//     String? contentId,
//     String? contentType,
//     bool? isFocused,
//     bool? liveStatus,
//     bool? isYoutubeVideo,
//     Duration? position, // Include new field
//   }) {
//     return NewsItemModel(
//       id: id ?? this.id,
//       index: id ?? this.index,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       thumbnail: thumbnail ?? this.thumbnail,
//       banner: banner ?? this.banner,
//       poster: poster ?? this.poster,
//       category: category ?? this.category,
//       url: url ?? this.url,
//       videoId: url ?? this.videoId,
//       streamType: streamType ?? this.streamType,
//       type: streamType ?? this.type,
//       genres: genres ?? this.genres,
//       status: status ?? this.status,
//       contentId: contentId ?? this.contentId,
//       contentType: contentType ?? this.contentType,
//       isFocused: isFocused ?? this.isFocused,
//       liveStatus: liveStatus ?? this.liveStatus,
//       isYoutubeVideo: isYoutubeVideo ?? this.isYoutubeVideo,
//       position: position ?? this.position, // Copy or default to the current value
//     );
//   }
// }




class NewsItemModel {
  final String id;
  final String index;
  final String name;
  final String description;
  final String thumbnail_high;
  final String banner;
  final String poster;
  final String url;
  final String videoId;
  final String streamType;
  final String type;
  final String genres;
  final String status;
  final String category;
  final String contentId;
  final String contentType;
  final bool isYoutubeVideo;
  bool isFocused;
  final Duration position;
  bool liveStatus;

  // Episode-specific fields
  final String order;
  final String seasonId;
  final String downloadable;
  final String source;
  final String skipAvailable;
  final String introStart;
  final String introEnd;
  final String endCreditsMarker;
  final String drmUuid;
  final String drmLicenseUri;

  // Season-specific fields
  final String seasonName;
  final String webSeriesId;

  NewsItemModel({
    required this.id,
    this.index = '',
    required this.name,
    this.description = '',
    this.thumbnail_high = '',
    required this.banner,
    this.poster = '',
    required this.url,
    this.videoId = '',
    this.streamType = '',
    this.type = '',
    this.genres = '',
    this.status = '',
    this.category = '',
    this.contentId = '',
    this.contentType = '',
    this.isYoutubeVideo = false,
    this.isFocused = false,
    this.position = Duration.zero,
    this.liveStatus = false,
    // Episode fields
    this.order = '',
    this.seasonId = '',
    this.downloadable = '',
    this.source = '',
    this.skipAvailable = '',
    this.introStart = '',
    this.introEnd = '',
    this.endCreditsMarker = '',
    this.drmUuid = '',
    this.drmLicenseUri = '',
    // Season fields
    this.seasonName = '',
    this.webSeriesId = '',
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    return NewsItemModel(
      id: json['id']?.toString() ?? '',
      index: json['index']?.toString() ?? '',
      name: json['name'] ?? json['Episoade_Name'] ?? json['session_name'] ?? '',
      description: json['description'] ?? json['episoade_description'] ?? json['session_description'] ?? '',
      thumbnail_high: json['thumbnail_high'] ?? '',
      banner: json['banner'] ?? json['session_image'] ?? json['episoade_image'] ?? '',
      poster: json['poster'] ?? '',
      url: json['url'] ?? '',
      videoId: json['videoId'] ?? '',
      streamType: json['stream_type'] ?? '',
      type: json['type'] ?? '',
      genres: json['genres'] ?? '',
      status: json['status'] ?? '',
      category: json['category'] ?? '',
      contentId: json['content_id'] ?? '',
      contentType: json['content_type'] ?? '',
      isYoutubeVideo: json['content_type'] == "1",
      isFocused: json['isFocused'] ?? false,
      liveStatus: json['liveStatus'] ?? false,
      position: Duration(milliseconds: json['position'] ?? 0),
      // Episode-specific fields
      order: json['episoade_order'] ?? '',
      seasonId: json['season_id'] ?? '',
      downloadable: json['downloadable'] ?? '',
      source: json['source'] ?? '',
      skipAvailable: json['skip_available'] ?? '',
      introStart: json['intro_start'] ?? '',
      introEnd: json['intro_end'] ?? '',
      endCreditsMarker: json['end_credits_marker'] ?? '',
      drmUuid: json['drm_uuid'] ?? '',
      drmLicenseUri: json['drm_license_uri'] ?? '',
      // Season-specific fields
      seasonName: json['session_name'] ?? '',
      webSeriesId: json['web_series_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'name': name,
      'description': description,
      'thumbnail_high': thumbnail_high,
      'banner': banner,
      'poster': poster,
      'url': url,
      'videoId': videoId,
      'stream_type': streamType,
      'type': type,
      'genres': genres,
      'status': status,
      'category': category,
      'content_id': contentId,
      'content_type': contentType,
      'isFocused': isFocused,
      'liveStatus': liveStatus,
      'isYoutubeVideo': isYoutubeVideo,
      'position': position.inMilliseconds,
      // Episode-specific fields
      'episoade_order': order,
      'season_id': seasonId,
      'downloadable': downloadable,
      'source': source,
      'skip_available': skipAvailable,
      'intro_start': introStart,
      'intro_end': introEnd,
      'end_credits_marker': endCreditsMarker,
      'drm_uuid': drmUuid,
      'drm_license_uri': drmLicenseUri,
      // Season-specific fields
      'session_name': seasonName,
      'web_series_id': webSeriesId,
    };
  }

  NewsItemModel copyWith({
    String? id,
    String? index,
    String? name,
    String? description,
    String? thumbnail_high,
    String? banner,
    String? poster,
    String? url,
    String? videoId,
    String? streamType,
    String? type,
    String? genres,
    String? status,
    String? category,
    String? contentId,
    String? contentType,
    bool? isFocused,
    bool? liveStatus,
    bool? isYoutubeVideo,
    Duration? position,
    // Episode-specific fields
    String? order,
    String? seasonId,
    String? downloadable,
    String? source,
    String? skipAvailable,
    String? introStart,
    String? introEnd,
    String? endCreditsMarker,
    String? drmUuid,
    String? drmLicenseUri,
    // Season-specific fields
    String? seasonName,
    String? webSeriesId,
  }) {
    return NewsItemModel(
      id: id ?? this.id,
      index: index ?? this.index,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnail_high: thumbnail_high ?? this.thumbnail_high,
      banner: banner ?? this.banner,
      poster: poster ?? this.poster,
      url: url ?? this.url,
      videoId: videoId ?? this.videoId,
      streamType: streamType ?? this.streamType,
      type: type ?? this.type,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      category: category ?? this.category,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      isFocused: isFocused ?? this.isFocused,
      liveStatus: liveStatus ?? this.liveStatus,
      isYoutubeVideo: isYoutubeVideo ?? this.isYoutubeVideo,
      position: position ?? this.position,
      // Episode-specific fields
      order: order ?? this.order,
      seasonId: seasonId ?? this.seasonId,
      downloadable: downloadable ?? this.downloadable,
      source: source ?? this.source,
      skipAvailable: skipAvailable ?? this.skipAvailable,
      introStart: introStart ?? this.introStart,
      introEnd: introEnd ?? this.introEnd,
      endCreditsMarker: endCreditsMarker ?? this.endCreditsMarker,
      drmUuid: drmUuid ?? this.drmUuid,
      drmLicenseUri: drmLicenseUri ?? this.drmLicenseUri,
      // Season-specific fields
      seasonName: seasonName ?? this.seasonName,
      webSeriesId: webSeriesId ?? this.webSeriesId,
    );
  }
}
