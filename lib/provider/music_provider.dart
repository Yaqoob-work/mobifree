import 'package:flutter/material.dart';
import '../widgets/models/news_item_model.dart';

class MusicProvider with ChangeNotifier {
  List<NewsItemModel> _musicList = [];

  List<NewsItemModel> get musicList => _musicList;

  void setMusicList(List<NewsItemModel> newMusicList) {
    _musicList = newMusicList;
    notifyListeners();
  }

  NewsItemModel? get firstBanner =>
      _musicList.isNotEmpty ? _musicList[0] : null;
}
