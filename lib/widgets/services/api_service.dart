



import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_item_model.dart';

class ApiService {

    ApiService();

  Future<void> updateCacheOnPageEnter() async {
    await _updateCacheInBackground();
  }

  List<NewsItemModel> allChannelList = [];
  List<NewsItemModel> newsList = [];
  List<NewsItemModel> movieList = [];
  List<NewsItemModel> musicList = [];
  List<NewsItemModel> entertainmentList = [];
  List<NewsItemModel> religiousList = [];
  List<NewsItemModel> sportsList = [];
  List<int> allowedChannelIds = [];
  bool tvenableAll = false;

  final _updateController = StreamController<bool>.broadcast();
  Stream<bool> get updateStream => _updateController.stream;



  Future<void> fetchSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSettings = prefs.getString('settings');

      if (cachedSettings != null) {
        final settingsData = json.decode(cachedSettings);
        allowedChannelIds = List<int>.from(settingsData['channels']);
        tvenableAll = settingsData['tvenableAll'] == 1;
      } else {
        await _fetchAndCacheSettings();
      }
    } catch (e) {
      throw Exception('Error fetching settings');
    }
  }

  Future<void> _fetchAndCacheSettings() async {
    final response = await http.get(
      Uri.parse('https://api.ekomflix.com/android/getSettings'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      final settingsData = json.decode(response.body);
      allowedChannelIds = List<int>.from(settingsData['channels']);
      tvenableAll = settingsData['tvenableAll'] == 1;

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('settings', response.body);
    } else {
      throw Exception('Failed to load settings');
    }
  }

  Future<void> fetchEntertainment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEntertainment = prefs.getString('entertainment');

      if (cachedEntertainment != null) {
        final List<dynamic> responseData = json.decode(cachedEntertainment);
        _processEntertainmentData(responseData);
      } else {
        await _fetchAndCacheEntertainment();
      }
    } catch (e) {
      throw Exception('Error fetching entertainment data');
    }
  }

  Future<void> _fetchAndCacheEntertainment() async {
    final response = await http.get(
      Uri.parse('https://api.ekomflix.com/android/getFeaturedLiveTV'),
      headers: {'x-api-key': 'vLQTuPZUxktl5mVW'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      _processEntertainmentData(responseData);

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('entertainment', response.body);
    } else {
      throw Exception('Failed to load entertainment data');
    }
  }

  void _processEntertainmentData(List<dynamic> responseData) {
    allChannelList = responseData
        .where((channel) => _isChannelAllowed(channel))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    newsList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('News'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    movieList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('Movie'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    musicList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('Music'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    entertainmentList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('Entertainment'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    religiousList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('Religious'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();

    sportsList = responseData
        .where((channel) =>
            _isChannelAllowed(channel) &&
            channel['genres'].toString().contains('Sports'))
        .map((channel) => NewsItemModel.fromJson(channel))
        .toList();
  }

  bool _isChannelAllowed(dynamic channel) {
    int channelId = int.tryParse(channel['id'].toString()) ?? 0;
    String channelStatus = channel['status'].toString();
    return channelStatus == "1" &&
        (tvenableAll || allowedChannelIds.contains(channelId));
  }

  Future<void> _updateCacheInBackground() async {
    try {
      bool hasChanges = false;

      final oldSettings = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('settings'));
      await _fetchAndCacheSettings();
      final newSettings = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('settings'));
      if (oldSettings != newSettings) hasChanges = true;

      final oldEntertainment = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('entertainment'));
      await _fetchAndCacheEntertainment();
      final newEntertainment = await SharedPreferences.getInstance()
          .then((prefs) => prefs.getString('entertainment'));
      if (oldEntertainment != newEntertainment) hasChanges = true;

      if (hasChanges) {
        _updateController.add(true);
      }
    } catch (e) {
      print('Error updating cache in background: $e');
    }
  }

  

  void dispose() {
    _updateController.close();
  }
}