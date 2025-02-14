import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeHelper {
  static final yt = YoutubeExplode();

  static Future<String> getPlayableUrl(String youtubeIdOrUrl) async {
    try {
      String videoId;
      
      // Check if direct video ID
      if (youtubeIdOrUrl.length == 11 && !youtubeIdOrUrl.contains('/')) {
        videoId = youtubeIdOrUrl;
      } 
      // Check youtu.be format
      else if (youtubeIdOrUrl.contains('youtu.be/')) {
        videoId = youtubeIdOrUrl.split('youtu.be/')[1];
        videoId = videoId.split('?')[0]; // Remove query parameters
      } 
      // Check youtube.com format
      else if (youtubeIdOrUrl.contains('youtube.com/watch')) {
        var uri = Uri.parse(youtubeIdOrUrl);
        videoId = uri.queryParameters['v'] ?? '';
      } 
      // Check shorts format
      else if (youtubeIdOrUrl.contains('youtube.com/shorts/')) {
        videoId = youtubeIdOrUrl.split('shorts/')[1];
        videoId = videoId.split('?')[0]; // Remove query parameters
      } else {
        throw Exception('Invalid YouTube URL format');
      }

      if (videoId.isEmpty) {
        throw Exception('Could not extract video ID');
      }

      print('Extracted video ID: $videoId');

      // Get streams manifest
      var manifest = await yt.videos.streams.getManifest(videoId);
      
      // Try to get highest quality muxed stream
      var streamInfo = manifest.muxed.withHighestBitrate();
      if (streamInfo != null) {
        print('Found stream URL: ${streamInfo.url}');
        return streamInfo.url.toString();
      }

      throw Exception('No playable stream found');
    } catch (e) {
      print('Error getting YouTube URL: $e');
      rethrow;
    }
  }

  static bool isValidYoutubeUrl(String url) {
    if (url.isEmpty) return false;
    
    url = url.toLowerCase();
    
    // Check for direct video ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return true;
    }

    // Check common YouTube URL patterns
    return url.contains('youtube.com/watch') ||
           url.contains('youtu.be/') ||
           url.contains('youtube.com/shorts/');
  }

  static void dispose() {
    yt.close();
  }
}