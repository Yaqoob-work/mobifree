// import 'package:flutter/foundation.dart';

// class SharedDataProvider extends ChangeNotifier {
//   List<Map<String, dynamic>> _lastPlayedVideos = [];

//   List<Map<String, dynamic>> get lastPlayedVideos => _lastPlayedVideos;

//   void updateLastPlayedVideos(List<Map<String, dynamic>> newVideos) {
//     _lastPlayedVideos = newVideos;
//     notifyListeners();
//   }
// }



import 'package:flutter/material.dart';

class SharedDataProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lastPlayedVideos = [];

  List<Map<String, dynamic>> get lastPlayedVideos => _lastPlayedVideos;

  void updateLastPlayedVideos(List<Map<String, dynamic>> videos) {
    _lastPlayedVideos = videos;
    notifyListeners();
  }

  void addLastPlayedVideo(Map<String, dynamic> video) {
    _lastPlayedVideos.insert(0, video); // Add the video at the top
    notifyListeners();
  }

  void clearLastPlayedVideos() {
    _lastPlayedVideos.clear();
    notifyListeners();
  }
}
