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

class SharedDataProviderMusiclist with ChangeNotifier {
  List<Map<String, dynamic>> _musicList = [];

  List<Map<String, dynamic>> get musicList => _musicList;

  void updateMusicList(List<Map<String, dynamic>> videos) {
    _musicList = videos;
    notifyListeners();
  }

  void addLastPlayedVideo(Map<String, dynamic> video) {
    _musicList.insert(0, video); // Add the video at the top
    notifyListeners();
  }

  void clearLastPlayedVideos() {
    _musicList.clear();
    notifyListeners();
  }
}
