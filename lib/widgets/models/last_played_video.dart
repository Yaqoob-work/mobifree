// // lib/models/last_played_video.dart
// class LastPlayedVideo {
//   final String videoUrl;
//   final String bannerImageUrl;
//   final String videoName;
//   final String videoId;
//   final Duration totalDuration;
//   final Duration currentPosition;

//   LastPlayedVideo({
//     required this.videoUrl,
//     required this.bannerImageUrl,
//     required this.videoName,
//     required this.videoId,
//     required this.totalDuration,
//     required this.currentPosition,
//   });

//   // Convert object to Map for saving in SharedPreferences
//   Map<String, dynamic> toJson() {
//     return {
//       'videoUrl': videoUrl,
//       'bannerImageUrl': bannerImageUrl,
//       'videoName': videoName,
//       'videoId': videoId,
//       'totalDuration': totalDuration.inMilliseconds,
//       'currentPosition': currentPosition.inMilliseconds,
//     };
//   }

//   // Create object from Map
//   factory LastPlayedVideo.fromJson(Map<String, dynamic> json) {
//     return LastPlayedVideo(
//       videoUrl: json['videoUrl'] ?? '',
//       bannerImageUrl: json['bannerImageUrl'] ?? '',
//       videoName: json['videoName'] ?? '',
//       videoId: json['videoId'] ?? '',
//       totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
//       currentPosition: Duration(milliseconds: json['currentPosition'] ?? 0),
//     );
//   }
// }



class VideoEntry {
  final String url;
  final Duration position;
  final String bannerImageUrl;
  final String videoName;
  final String videoId;
  final Duration totalDuration;

  VideoEntry({
    required this.url,
    required this.position,
    required this.bannerImageUrl,
    required this.videoName,
    required this.videoId,
    required this.totalDuration,
  });

  factory VideoEntry.fromString(String entry) {
    final details = entry.split('|');
    return VideoEntry(
      url: details[0],
      position: Duration(milliseconds: int.tryParse(details[1]) ?? 0),
      bannerImageUrl: details[2],
      videoName: details[3],
      videoId: details[4],
      totalDuration: Duration(milliseconds: int.tryParse(details[5]) ?? 0),
    );
  }

  @override
  String toString() {
    return '$url|${position.inMilliseconds}|$bannerImageUrl|$videoName|$videoId|${totalDuration.inMilliseconds}';
  }
}
