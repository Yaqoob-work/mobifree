

class Youtube {

  static bool isYoutubeUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    url = url.toLowerCase().trim();
    return RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url) ||
           url.contains('youtube.com') ||
           url.contains('youtu.be') ||
           url.contains('youtube.com/shorts/');
  }


}