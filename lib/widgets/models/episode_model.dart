
// Episode Model
class EpisodeModel {
  final String id;
  final String name;
  final String image;
  final String description;
  final String order;
  final String seasonId;
  final String downloadable;
  final String type;
  final String status;
  final String source;
  final String url;
  final String skipAvailable;
  final String introStart;
  final String introEnd;
  final String endCreditsMarker;
  final String drmUuid;
  final String drmLicenseUri;
    final String banner;     // Added banner property
  final String contentType; // Added contentType property

  EpisodeModel({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.order,
    required this.seasonId,
    required this.downloadable,
    required this.type,
    required this.status,
    required this.source,
    required this.url,
    required this.skipAvailable,
    required this.introStart,
    required this.introEnd,
    required this.endCreditsMarker,
    required this.drmUuid,
    required this.drmLicenseUri,
        this.banner = "",       // Default value
    this.contentType = "",  // Default value
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] ?? '',
      name: json['Episoade_Name'] ?? '',
      image: json['episoade_image'] ?? '',
      description: json['episoade_description'] ?? '',
      order: json['episoade_order'] ?? '',
      seasonId: json['season_id'] ?? '',
      downloadable: json['downloadable'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      source: json['source'] ?? '',
      url: json['url'] ?? '',
      skipAvailable: json['skip_available'] ?? '',
      introStart: json['intro_start'] ?? '',
      introEnd: json['intro_end'] ?? '',
      endCreditsMarker: json['end_credits_marker'] ?? '',
      drmUuid: json['drm_uuid'] ?? '',
      drmLicenseUri: json['drm_license_uri'] ?? '',
            banner: json['banner'] ?? '',
      contentType: json['contentType'] ?? '',
    );
  }
}