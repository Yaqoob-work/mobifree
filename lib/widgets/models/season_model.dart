class SeasonModel {
  final String id;
  final String session_name;
  final String image;
  final String description;
  final String webSeriesId;
  final String status;

  SeasonModel({
    required this.id,
    required this.session_name,
    required this.image,
    required this.description,
    required this.webSeriesId,
    required this.status,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'] ?? '',
      session_name: json['session_name'] ?? '',
      image: json['session_image'] ?? '',
      description: json['session_description'] ?? '',
      webSeriesId: json['web_series_id'] ?? '',
      status: json['status'] ?? '',
    );
  }
}